extends Node2D

signal user_confirmed
signal board_completed 

var tile_size = Vector2(120, 94) 
var offset = Vector2(10, 10)
var start_pos = Vector2(0, 0) 
var current_stage = 1
var total_score = 0

var spiral_path = [
	Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0),
	Vector2(3, 1), Vector2(3, 2), Vector2(3, 3), Vector2(3, 4),
	Vector2(2, 4), Vector2(1, 4), Vector2(0, 4),
	Vector2(0, 3), Vector2(0, 2), Vector2(0, 1),
	Vector2(1, 1), Vector2(2, 1),
	Vector2(2, 2), Vector2(2, 3),
	Vector2(1, 3),
	Vector2(1, 2)
]

var map_tiles = []
var chance_tiles = []

var player_node: Panel 
var current_tile_index = 0
var move_direction = 1 
var is_moving = false
var is_event_active = false
var is_waiting_confirm = false 

var bg: ColorRect       
var map_root: Node2D    
var ui_layer: CanvasLayer
var event_panel: ColorRect
var event_title: Label
var event_result: Label
var continue_btn: Button 
var roll_dice_btn: Button 

# 升階確認面板專用
var stage_panel: ColorRect
var stage_yes_btn: Button
var stage_no_btn: Button
signal _stage_choice_made(go_next: bool)

# 每個階段升階所需分數（升到階段 N+1 需要此分數）
const STAGE_THRESHOLDS = {
	1: 2000,  # 階段一 → 階段二
	2: 3000   # 階段二 → 階段三
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
	
	setup_ui()
	generate_chance_tiles()
	generate_map()
	create_player()
	
	_on_window_resized()

func _on_visibility_changed():
	if ui_layer:
		ui_layer.visible = self.visible

func _on_window_resized():
	var screen_size = get_viewport_rect().size
	if bg: bg.set_deferred("size", screen_size) 
	
	var map_size = Vector2(510, 510)
	if map_root:
		map_root.position = (screen_size - map_size) / 2.0
		
	if event_panel:
		event_panel.position = (screen_size - event_panel.size) / 2.0

	if stage_panel:
		stage_panel.position = (screen_size - stage_panel.size) / 2.0
		
	if roll_dice_btn:
		var map_bottom_y = (screen_size.y + map_size.y) / 2.0
		roll_dice_btn.position = Vector2((screen_size.x - 250) / 2.0, map_bottom_y - 40)

func setup_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	roll_dice_btn = Button.new()
	roll_dice_btn.text = "🎲 點擊擲骰子"
	roll_dice_btn.custom_minimum_size = Vector2(250, 80)
	roll_dice_btn.add_theme_font_size_override("font_size", 32)
	roll_dice_btn.set("theme_override_colors/font_color", Color.GOLD)
	roll_dice_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	roll_dice_btn.pressed.connect(_on_roll_dice_pressed)
	ui_layer.add_child(roll_dice_btn)
	roll_dice_btn.hide() 
	
	# ── 一般事件面板 ──
	event_panel = ColorRect.new()
	event_panel.color = Color(0, 0, 0, 0.85)
	event_panel.size = Vector2(400, 200)
	ui_layer.add_child(event_panel)
	
	event_title = Label.new()
	event_title.text = "標題"
	event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_title.position = Vector2(0, 20)
	event_title.size = Vector2(400, 50)
	event_title.add_theme_font_size_override("font_size", 24)
	event_panel.add_child(event_title)
	
	event_result = Label.new()
	event_result.text = "結果"
	event_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_result.position = Vector2(0, 75)
	event_result.size = Vector2(400, 100)
	event_result.add_theme_font_size_override("font_size", 48)
	event_panel.add_child(event_result)
	
	continue_btn = Button.new()
	continue_btn.text = "確認並繼續"
	continue_btn.custom_minimum_size = Vector2(150, 40)
	continue_btn.position = Vector2((400 - 150) / 2.0, 145)
	continue_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	continue_btn.pressed.connect(func():
		is_waiting_confirm = false
		user_confirmed.emit() 
	)
	event_panel.add_child(continue_btn)
	continue_btn.hide()
	event_panel.hide()

	# ── 升階確認面板 ──
	stage_panel = ColorRect.new()
	stage_panel.color = Color(0, 0, 0, 0.90)
	stage_panel.size = Vector2(460, 260)
	ui_layer.add_child(stage_panel)

	var sp_title = Label.new()
	sp_title.text = "🌀 抵達蟲洞！"
	sp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_title.position = Vector2(0, 18)
	sp_title.size = Vector2(460, 45)
	sp_title.add_theme_font_size_override("font_size", 26)
	sp_title.set("theme_override_colors/font_color", Color.GOLD)
	stage_panel.add_child(sp_title)

	var sp_desc = Label.new()
	sp_desc.name = "Desc"
	sp_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sp_desc.position = Vector2(20, 70)
	sp_desc.size = Vector2(420, 100)
	sp_desc.add_theme_font_size_override("font_size", 20)
	sp_desc.set("theme_override_colors/font_color", Color.WHITE)
	stage_panel.add_child(sp_desc)

	var sp_btn_hbox = HBoxContainer.new()
	sp_btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sp_btn_hbox.add_theme_constant_override("separation", 30)
	sp_btn_hbox.position = Vector2(0, 185)
	sp_btn_hbox.size = Vector2(460, 55)
	stage_panel.add_child(sp_btn_hbox)

	stage_yes_btn = Button.new()
	stage_yes_btn.text = "✅ 前往下一階段"
	stage_yes_btn.custom_minimum_size = Vector2(180, 48)
	stage_yes_btn.add_theme_font_size_override("font_size", 20)
	stage_yes_btn.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	stage_yes_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	stage_yes_btn.pressed.connect(func():
		stage_panel.hide()
		_stage_choice_made.emit(true)
	)
	sp_btn_hbox.add_child(stage_yes_btn)

	stage_no_btn = Button.new()
	stage_no_btn.text = "❌ 暫時不要"
	stage_no_btn.custom_minimum_size = Vector2(160, 48)
	stage_no_btn.add_theme_font_size_override("font_size", 20)
	stage_no_btn.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
	stage_no_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	stage_no_btn.pressed.connect(func():
		stage_panel.hide()
		_stage_choice_made.emit(false)
	)
	sp_btn_hbox.add_child(stage_no_btn)

	stage_panel.hide()

func activate_dice():
	if current_tile_index != 19:
		roll_dice_btn.show()

func _on_roll_dice_pressed():
	roll_dice_btn.hide()
	show_dice_roll()

func generate_chance_tiles():
	chance_tiles.clear()
	var valid_range = range(1, 19)
	while chance_tiles.size() < 3:
		var pick = valid_range[randi() % valid_range.size()]
		var is_valid = true
		for existing in chance_tiles:
			if abs(pick - existing) <= 3:
				is_valid = false
				break
		if is_valid: chance_tiles.append(pick)
	chance_tiles.sort()

func generate_map():
	# 清除舊地圖（升階重建時使用）
	for tile in map_tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	map_tiles.clear()

	for i in range(spiral_path.size()):
		var grid_pos = spiral_path[i]
		var tile = Panel.new()
		tile.size = tile_size
		tile.position = start_pos + Vector2(grid_pos.x * (tile_size.x + offset.x), grid_pos.y * (tile_size.y + offset.y))
		
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.shadow_color = Color(0, 0, 0, 0.25)
		style.shadow_size = 4
		style.shadow_offset = Vector2(2, 4)
		
		if i == 0: style.bg_color = Color("#FFDD44")     
		elif i == spiral_path.size() - 1: style.bg_color = Color("#00AEEF")     
		elif i in chance_tiles: style.bg_color = Color("#A366FF")     
		else: style.bg_color = Color.LIGHT_GRAY     
			
		tile.add_theme_stylebox_override("panel", style)
		map_root.add_child(tile)
		
		var label = Label.new()
		# 終點格顯示當前階段的升階分數門檻（如果有的話）
		if i == spiral_path.size() - 1:
			var threshold = STAGE_THRESHOLDS.get(current_stage, 0)
			if threshold > 0:
				label.text = "蟲洞\n(%d分)" % threshold
			else:
				label.text = "蟲洞\n(終點)"
		elif i == 0: label.text = "開始⮕"
		elif i in chance_tiles: label.text = "機會與\n命運"
		else: label.text = str(i)
			
		label.set("theme_override_colors/font_color", Color.WHITE if i in chance_tiles else Color.BLACK)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT) 
		label.add_theme_font_size_override("font_size", 20) 
		tile.add_child(label)
		map_tiles.append(tile)

func create_player():
	if is_instance_valid(player_node):
		player_node.queue_free()

	player_node = Panel.new()
	player_node.size = Vector2(56, 56) 
	var style = StyleBoxFlat.new()
	style.bg_color = Color.DODGER_BLUE
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	player_node.add_theme_stylebox_override("panel", style)
	
	player_node.position = map_tiles[current_tile_index].position + (tile_size - player_node.size) / 2.0
	player_node.z_index = 10 
	map_root.add_child(player_node)

func show_dice_roll():
	is_event_active = true
	event_panel.show()
	event_title.text = "🎲 擲骰子中..."
	
	for i in range(8):
		event_result.text = str(randi_range(1, 6))
		await get_tree().create_timer(0.03).timeout 
	
	var final_roll = randi_range(1, 6)
	event_result.text = str(final_roll) + " 步！"
	
	continue_btn.show()
	is_waiting_confirm = true
	await self.user_confirmed 
	
	continue_btn.hide()
	event_panel.hide()
	move_player(final_roll)

func move_player(steps: int):
	is_moving = true
	var tween = create_tween()
	
	for i in range(steps):
		var next_index = current_tile_index + move_direction
		if next_index < 0: move_direction = 1; next_index = 1
		elif next_index > 19: move_direction = -1; next_index = 18
			
		current_tile_index = next_index
		var target_pos = map_tiles[current_tile_index].position + (tile_size - player_node.size) / 2.0
		tween.tween_property(player_node, "position", target_pos, 0.25).set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(0.15)
	
	tween.finished.connect(_on_movement_finished)

func _on_movement_finished():
	is_moving = false
	if current_tile_index == 19:
		await _handle_end_tile()
	elif current_tile_index in chance_tiles:
		show_chance_wheel() 
	else:
		is_event_active = false 
		board_completed.emit() 

# ==========================================
# 🌀 終點格處理（升階邏輯）
# ==========================================
func _handle_end_tile():
	var threshold = STAGE_THRESHOLDS.get(current_stage, 0)

	# 沒有升階門檻 → 已是最終階段，直接完成
	if threshold == 0:
		is_event_active = false
		board_completed.emit()
		return

	# 分數不足 → 撞牆，掉頭逆時針往回走
	if total_score < threshold:
		event_panel.show()
		event_title.text = "🧱 撞牆了！"
		event_result.add_theme_font_size_override("font_size", 24)
		event_result.text = "分數不足 %d，無法升階\n下一天將往回走" % threshold
		continue_btn.show()
		is_waiting_confirm = true
		await self.user_confirmed
		continue_btn.hide()
		event_panel.hide()
		event_result.add_theme_font_size_override("font_size", 48)  # 還原字型

		move_direction = -1  # 逆時針掉頭
		is_event_active = false
		board_completed.emit()
		return

	# 分數足夠 → 詢問是否升階
	var desc_lbl = stage_panel.get_node("Desc") as Label
	desc_lbl.text = "你的分數已達 %d 分！\n要前往【階段 %d】嗎？" % [total_score, current_stage + 1]
	stage_panel.show()
	_on_window_resized()  # 確保面板置中

	var go_next = await self._stage_choice_made

	if go_next:
		# ── 升階 ──
		current_stage += 1
		move_direction = 1          # 重置為順時針
		current_tile_index = 0      # 回到起點
		generate_chance_tiles()     # 重新隨機機會格
		generate_map()              # 重建地圖（含新門檻文字）
		create_player()             # 重建玩家圓形（放到新起點）
		_on_window_resized()
	else:
		# ── 選擇不升階：撞牆，掉頭 ──
		move_direction = -1
	
	is_event_active = false
	board_completed.emit()

func show_chance_wheel():
	event_panel.show()
	event_title.text = "✨ 機會與命運轉盤 ✨"
	var options = ["前進 ?", "後退 ?", "加分 !", "扣分 !"]
	
	for i in range(12):
		event_result.text = options[randi() % 4]
		await get_tree().create_timer(0.03).timeout
	
	var final_option = randi() % 4 + 1
	var n = 0; var m = 0; var result_text = ""
	var m_base = 450 * current_stage
	var m_variance = 50 * current_stage
	
	match final_option:
		1: n = randi_range(1, 6); result_text = "前進 " + str(n) + " 格！"
		2: n = randi_range(1, 6); result_text = "後退 " + str(n) + " 格！"
		3: m = randi_range(m_base - m_variance, m_base + m_variance); result_text = "加 " + str(m) + " 分！"
		4: m = randi_range(m_base - m_variance, m_base + m_variance); result_text = "減 " + str(m) + " 分！"
		
	event_result.text = result_text
	
	continue_btn.show()
	is_waiting_confirm = true
	await self.user_confirmed 
	
	continue_btn.hide()
	event_panel.hide()
	
	match final_option:
		1: move_direction = 1; move_player(n) 
		2: move_direction = -1; move_player(n)
		3: total_score += m; is_event_active = false; board_completed.emit() 
		4: total_score -= m; is_event_active = false; board_completed.emit() 

func _input(event):
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		if is_waiting_confirm:
			is_waiting_confirm = false
			user_confirmed.emit()
