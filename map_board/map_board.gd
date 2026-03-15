extends Node2D
## MapBoard 主控制器
## UI 面板委託給 MapUIBuilder
## 地圖生成委託給 MapGenerator
## 事件邏輯委託給 MapEvents

signal user_confirmed
signal board_completed

var current_stage = 1
var total_score = 0

var map_tiles = []
var chance_tiles = []

var player_node: Panel
var current_tile_index = 0
var move_direction = 1
var is_moving = false
var is_event_active = false
var is_waiting_confirm = false

# 作弊模式
var cheat_forced_dice_value = 0  # > 0 時使用指定骰子值

# UI 參照
var bg: ColorRect
var map_root: Node2D
var ui_layer: CanvasLayer
var event_panel: ColorRect
var event_title: Label
var event_result: Label
var continue_btn: Button
var roll_dice_btn: Button
var stage_panel: ColorRect
var stage_yes_btn: Button
var stage_no_btn: Button
var chest_panel: ColorRect
var chest_reward_lbl: Label
var chest_claim_btn: Button
var new_reward_panel: ColorRect
var new_reward_edit: LineEdit
var new_reward_confirm_btn: Button

signal _stage_choice_made(go_next: bool)
signal _chest_claimed
signal _new_reward_confirmed

const STAGE_THRESHOLDS = {
	1: 2000,
	2: 3000,
	3: 3500
}

func _ready():
	randomize()
	bg = ColorRect.new()
	bg.color = Color("#EDE9E3")
	add_child(bg)

	map_root = Node2D.new()
	add_child(map_root)

	get_viewport().size_changed.connect(_on_window_resized)
	self.visibility_changed.connect(_on_visibility_changed)

	_setup_ui()
	chance_tiles = MapGenerator.generate_chance_tiles()  # ← 新增這行
	_rebuild_map()
	_on_window_resized()

func _setup_ui():
	var refs = MapUIBuilder.build(self)
	ui_layer      = refs["ui_layer"]
	roll_dice_btn = refs["roll_dice_btn"]
	event_panel   = refs["event_panel"]
	event_title   = refs["event_title"]
	event_result  = refs["event_result"]
	continue_btn  = refs["continue_btn"]
	stage_panel   = refs["stage_panel"]
	stage_yes_btn = refs["stage_yes_btn"]
	stage_no_btn  = refs["stage_no_btn"]
	chest_panel      = refs["chest_panel"]
	chest_reward_lbl = refs["chest_reward_lbl"]
	chest_claim_btn  = refs["chest_claim_btn"]
	new_reward_panel      = refs["new_reward_panel"]
	new_reward_edit       = refs["new_reward_edit"]
	new_reward_confirm_btn = refs["new_reward_confirm_btn"]

	roll_dice_btn.pressed.connect(_on_roll_dice_pressed)
	continue_btn.pressed.connect(func():
		is_waiting_confirm = false
		user_confirmed.emit()
	)
	stage_yes_btn.pressed.connect(func():
		stage_panel.hide()
		_stage_choice_made.emit(true)
	)
	stage_no_btn.pressed.connect(func():
		stage_panel.hide()
		_stage_choice_made.emit(false)
	)
	chest_claim_btn.pressed.connect(func():
		chest_panel.hide()
		_chest_claimed.emit()
	)
	new_reward_confirm_btn.pressed.connect(func():
		new_reward_panel.hide()
		_new_reward_confirmed.emit()
	)

func _rebuild_map():
	# 清除舊地圖
	for tile in map_tiles:
		if is_instance_valid(tile): tile.queue_free()
	map_tiles.clear()
	if is_instance_valid(player_node): player_node.queue_free()

	map_tiles = MapGenerator.generate_map(map_root, chance_tiles, current_stage, STAGE_THRESHOLDS)
	player_node = MapGenerator.create_player(map_root, map_tiles, current_tile_index)

# ==========================================
# 視窗與可見性
# ==========================================
func _on_visibility_changed():
	if ui_layer: ui_layer.visible = self.visible

func _on_window_resized():
	var screen_size = get_viewport_rect().size
	if bg: bg.set_deferred("size", screen_size)

	var map_size = Vector2(510, 510)
	if map_root: map_root.position = (screen_size - map_size) / 2.0
	if event_panel: event_panel.position = (screen_size - event_panel.size) / 2.0
	if stage_panel: stage_panel.position = (screen_size - stage_panel.size) / 2.0
	if chest_panel: chest_panel.position = (screen_size - chest_panel.size) / 2.0
	if new_reward_panel: new_reward_panel.position = (screen_size - new_reward_panel.size) / 2.0
	if roll_dice_btn:
		var map_bottom_y = (screen_size.y + map_size.y) / 2.0
		roll_dice_btn.position = Vector2((screen_size.x - 250) / 2.0, map_bottom_y - 40)

# ==========================================
# 骰子與移動
# ==========================================
func activate_dice():
	if current_tile_index != 19 or move_direction == -1:
		roll_dice_btn.show()

func _on_roll_dice_pressed():
	roll_dice_btn.hide()
	_show_dice_roll()

func _show_dice_roll():
	is_event_active = true
	var forced = cheat_forced_dice_value
	cheat_forced_dice_value = 0  # 用完即重置
	var final_roll = await MapEvents.animate_dice(event_panel, event_title, event_result, get_tree(), forced)

	continue_btn.show()
	is_waiting_confirm = true
	await self.user_confirmed

	continue_btn.hide()
	event_panel.hide()
	_move_player(final_roll)

func _move_player(steps: int):
	is_moving = true
	var tween = create_tween()

	for i in range(steps):
		var next_index = current_tile_index + move_direction
		if next_index < 0: move_direction = 1; next_index = 1
		elif next_index > 19: move_direction = -1; next_index = 18

		current_tile_index = next_index
		var target_pos = map_tiles[current_tile_index].position + (MapGenerator.TILE_SIZE - player_node.size) / 2.0
		tween.tween_property(player_node, "position", target_pos, 0.25).set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(0.15)

	tween.finished.connect(_on_movement_finished)

func _on_movement_finished():
	is_moving = false
	if current_tile_index == 19:
		await _handle_end_tile()
	elif current_tile_index in chance_tiles:
		_show_chance_wheel()
	else:
		is_event_active = false
		board_completed.emit()

# ==========================================
# 🌀 終點格處理
# ==========================================
func _handle_end_tile():
	var status = MapEvents.evaluate_end_tile(total_score, current_stage, STAGE_THRESHOLDS)

	if status == "no_threshold":
		is_event_active = false
		board_completed.emit()
		return

	if status == "insufficient":
		var threshold = MapEvents.get_threshold(current_stage, STAGE_THRESHOLDS)
		event_panel.show()
		event_title.text = "🧱 撞牆了！"
		event_result.add_theme_font_size_override("font_size", 24)
		event_result.text = "分數不足 %d，無法升階\n下一天將往回走" % threshold
		continue_btn.show()
		is_waiting_confirm = true
		await self.user_confirmed
		continue_btn.hide()
		event_panel.hide()
		event_result.add_theme_font_size_override("font_size", 48)

		move_direction = -1
		is_event_active = false
		board_completed.emit()
		return

	# ask_player — 第三階段特殊處理
	if current_stage == 3:
		await _handle_stage3_completion()
		return

	# 一般升階
	var desc_lbl = stage_panel.get_node("Desc") as Label
	desc_lbl.text = "你的分數已達 %d 分！\n要前往【階段 %d】嗎？" % [total_score, current_stage + 1]
	stage_panel.show()
	_on_window_resized()

	var go_next = await self._stage_choice_made

	if go_next:
		current_stage += 1
		move_direction = 1
		current_tile_index = 0
		chance_tiles = MapGenerator.generate_chance_tiles()
		_rebuild_map()
		_on_window_resized()
	else:
		move_direction = -1

	is_event_active = false
	board_completed.emit()

# ==========================================
# 🎁 第三階段完成 — 開寶箱 + 重設
# ==========================================
func _handle_stage3_completion():
	# 顯示開寶箱畫面
	var reward_text = SaveManager.reward_item
	if reward_text != "":
		chest_reward_lbl.text = "你獲得了你的獎勵：\n「%s」！🎊" % reward_text
	else:
		chest_reward_lbl.text = "你成功完成了所有挑戰！🎊\n繼續向下一個目標前進吧！"
	chest_panel.show()
	_on_window_resized()

	await self._chest_claimed

	# 顯示設定新獎勵面板
	new_reward_edit.text = ""
	new_reward_panel.show()
	_on_window_resized()

	await self._new_reward_confirmed

	# 儲存新獎勵
	var new_reward = new_reward_edit.text.strip_edges()
	SaveManager.reward_item = new_reward

	# 重設回第一階段起點
	total_score = 0
	current_stage = 1
	move_direction = 1
	current_tile_index = 0
	chance_tiles.clear()
	_rebuild_map()
	_on_window_resized()

	SaveManager.total_accumulated_score = 0 
	is_event_active = false
	board_completed.emit()

# ==========================================
# ✨ 機會轉盤
# ==========================================
func _show_chance_wheel():
	var result = await MapEvents.animate_chance_wheel(event_panel, event_title, event_result, current_stage, get_tree())

	continue_btn.show()
	is_waiting_confirm = true
	await self.user_confirmed

	continue_btn.hide()
	event_panel.hide()

	match result["type"]:
		"move_forward":
			move_direction = 1
			_move_player(result["value"])
		"move_backward":
			move_direction = -1
			_move_player(result["value"])
		"add_score":
			total_score += result["value"]
			is_event_active = false
			board_completed.emit()
		"sub_score":
			total_score -= result["value"]
			is_event_active = false
			board_completed.emit()

# ==========================================
# 🛠️ 作弊模式接口
# ==========================================

## 瞬間移動棋子到指定格子（不觸發事件）
func cheat_teleport_to(index: int):
	index = clampi(index, 0, 19)
	current_tile_index = index
	if is_instance_valid(player_node) and map_tiles.size() > index:
		player_node.position = map_tiles[index].position + (MapGenerator.TILE_SIZE - player_node.size) / 2.0

# ==========================================
# 輸入處理
# ==========================================
func _input(event):
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		if is_waiting_confirm:
			is_waiting_confirm = false
			user_confirmed.emit()
