extends Control
## 遊戲主場景控制器
## 頂部按鈕列委託給 TopBarBuilder

var global_score = 0
var global_day = 1
var global_stage = 1

@onready var todo_board = $TodoList
@onready var map_board = $MapBoard
@onready var profile_board = $UserProfile

var profile_btn: Button
var switch_btn: Button

var is_board_finished = false
var is_on_map = false
var is_switch_hovered = false
signal _planned_choice_made(use: bool)
var cheat_panel: CheatPanel

func _ready():	
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	_setup_top_bar()

	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()

	todo_board.finish_confirmed.connect(_on_todo_finished)
	todo_board.request_save.connect(_on_todo_request_save)
	map_board.board_completed.connect(_on_map_completed)

	_load_from_save_manager()
	await _check_new_day()
	map_board.hide()
	profile_board.hide()
	todo_board.show()

	# 🛠️ 作弊面板（F12 開關）
	cheat_panel = CheatPanel.new()
	add_child(cheat_panel)
	cheat_panel.setup(map_board, self)

func _setup_top_bar():
	var refs = TopBarBuilder.build(self)
	profile_btn  = refs["profile_btn"]
	switch_btn   = refs["switch_btn"]

	profile_btn.pressed.connect(_on_profile_pressed)
	switch_btn.pressed.connect(_on_switch_pressed)

	switch_btn.mouse_entered.connect(func():
		is_switch_hovered = true
		_update_switch_btn_text()
	)
	switch_btn.mouse_exited.connect(func():
		is_switch_hovered = false
		_update_switch_btn_text()
	)

# ==========================================
# 📂 從 SaveManager 還原進度
# ==========================================
func _load_from_save_manager():
	global_score = SaveManager.total_accumulated_score
	global_day   = SaveManager.actual_day
	global_stage = SaveManager.current_stage

	todo_board.task_history            = SaveManager.task_history
	todo_board.actual_day              = SaveManager.actual_day
	todo_board.current_view_day        = SaveManager.actual_day
	todo_board.total_accumulated_score = SaveManager.total_accumulated_score
	todo_board.current_stage           = SaveManager.current_stage
	todo_board.daily_points_limit      = SaveManager.current_stage * 100
	todo_board.update_day_navigation()

	map_board.current_stage      = SaveManager.current_stage
	map_board.total_score        = SaveManager.total_accumulated_score
	map_board.current_tile_index = SaveManager.map_tile_index
	map_board.move_direction     = SaveManager.map_move_direction
	map_board.chance_tiles = SaveManager.map_chance_tiles
	map_board.chance_tiles = SaveManager.map_chance_tiles
	if map_board.chance_tiles.is_empty():
		map_board.chance_tiles = MapGenerator.generate_chance_tiles()
	
	print("🗺️ [Main] 套用至 map_board.chance_tiles: ", map_board.chance_tiles)
	
	map_board._rebuild_map()
	map_board._on_window_resized()

	profile_board.user_name     = SaveManager.user_name
	profile_board.reward_item   = SaveManager.reward_item
	profile_board.total_score   = SaveManager.total_accumulated_score
	profile_board.current_stage = SaveManager.current_stage
	profile_board.play_days     = SaveManager.actual_day
	profile_board.update_display()

	todo_board.today_total_score = SaveManager.today_total_score
	if SaveManager.current_day_tasks.size() > 0:
		todo_board.restore_tasks_from_save(
			SaveManager.current_day_tasks,
			SaveManager.is_day_locked,
			SaveManager.is_day_finished,
			SaveManager.today_total_score
		)
	if SaveManager.next_day_tasks.size() > 0:
		todo_board.restore_next_day_from_save(
			SaveManager.next_day_tasks,
			SaveManager.is_next_day_locked
		)
	_sync_all_data()

# ==========================================
# 🔄 寫回 SaveManager 並存檔
# ==========================================
func _save_to_save_manager():
	SaveManager.last_played_date = _get_today_string()
	SaveManager.total_accumulated_score = global_score
	SaveManager.actual_day              = global_day
	SaveManager.current_stage           = global_stage
	SaveManager.task_history            = todo_board.task_history
	SaveManager.map_tile_index          = map_board.current_tile_index
	SaveManager.map_move_direction      = map_board.move_direction
	SaveManager.map_chance_tiles = map_board.chance_tiles
	SaveManager.next_day_tasks     = todo_board.serialize_next_day_tasks()
	SaveManager.is_next_day_locked = not todo_board.next_day_editing
	
	print("💾 [Main] 存檔時 chance_tiles: ", map_board.chance_tiles)
	
	SaveManager.user_name               = profile_board.user_name
	SaveManager.reward_item             = profile_board.reward_item
	SaveManager.today_total_score  = todo_board.today_total_score
	SaveManager.current_day_tasks  = todo_board.serialize_tasks()
	SaveManager.is_day_locked      = not todo_board.is_editing
	SaveManager.is_day_finished    = (todo_board.finish_btn.text == "已結算")
	# 同步歷史紀錄
	SaveManager.task_history       = todo_board.task_history
	SaveManager.next_day_tasks     = todo_board.serialize_next_day_tasks()
	SaveManager.is_next_day_locked = not todo_board.next_day_editing
	SaveManager.save_to_cloud()

# ==========================================
# 資料同步 & UI 更新
# ==========================================
func _sync_all_data():
	todo_board.total_accumulated_score = global_score
	todo_board.current_stage = global_stage
	todo_board.update_score_display()
	map_board.total_score = global_score
	map_board.current_stage = global_stage
	profile_board.total_score = global_score
	profile_board.current_stage = global_stage
	profile_board.play_days = global_day
	profile_board.move_direction = map_board.move_direction
	profile_board.update_display()

func _update_switch_btn_text():
	if is_switch_hovered:
		switch_btn.text = "📝 切換回任務" if is_on_map else "🗺️ 切換至地圖"
	else:
		switch_btn.text = "📝" if is_on_map else "🗺️"

func _on_window_resized():
	var screen_size = get_viewport_rect().size

# ==========================================
# 按鈕回呼
# ==========================================
func _on_profile_pressed():
	if todo_board.visible: global_score = todo_board.total_accumulated_score
	elif map_board.visible: global_score = map_board.total_score
	_sync_all_data()
	profile_board.show()

func _on_switch_pressed():
	if not is_on_map:
		is_on_map = true
		todo_board.hide()
		map_board.show()
	else:
		is_on_map = false
		map_board.hide()
		todo_board.show()

	_update_switch_btn_text()

# ==========================================
# 💾 存檔節點：todo_list 內部觸發（勾選、確認儲存）
# ==========================================
func _on_todo_request_save():
	global_score = todo_board.total_accumulated_score
	_sync_all_data()
	_save_to_save_manager()

# ==========================================
# 💾 存檔節點 1：結算今日得分
# 玩家確認任務完成、分數底定，是重要進度點
# ==========================================
func _on_todo_finished():
	global_score = todo_board.total_accumulated_score
	is_board_finished = true
	_sync_all_data()

	is_on_map = true
	todo_board.hide()
	map_board.show()
	_update_switch_btn_text()

	map_board.activate_dice()

	# 存檔：任務結算完成
	_save_to_save_manager()

# ==========================================
# 💾 存檔節點 2：地圖事件結束（每次骰子走完）
# 包含機會格、升降階、一般格落地
# ==========================================
func _on_map_completed():
	global_score = map_board.total_score
	global_stage = map_board.current_stage
	_sync_all_data()
	map_board.show_today_done()
	_save_to_save_manager()

# ==========================================
# 💾 存檔節點 3：進入下一天
# ==========================================
func _get_today_string() -> String:
	var t = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [t.year, t.month, t.day]

func _check_new_day():
	var today = _get_today_string()
	if SaveManager.last_played_date == "" or SaveManager.last_played_date == today:
		return

	print("📅 [Main] 偵測到新的一天（上次：%s，今天：%s）" % [SaveManager.last_played_date, today])

	var has_planned = SaveManager.next_day_tasks.size() > 0
	var use_planned = false

	if has_planned:
		use_planned = await _show_planned_tasks_prompt()

	var planned_tasks = SaveManager.next_day_tasks.duplicate(true) if use_planned else []

	global_day += 1
	_sync_all_data()
	todo_board.new_day_from_login()

	if use_planned:
		todo_board.load_planned_tasks_as_today(planned_tasks)

	_save_to_save_manager()
## 作弊面板用：前進或後退指定天數

func cheat_advance_day(delta: int) -> void:
	if delta > 0:
		for i in range(delta):
			global_day += 1
			todo_board.new_day_from_login()  # 會自行 +1 actual_day 並重置任務列
	elif delta < 0:
		global_day = max(1, global_day + delta)
		todo_board.actual_day = global_day
		todo_board.current_view_day = global_day
		todo_board.update_day_navigation()
	_sync_all_data()
	_save_to_save_manager()

## 新增提示方法 _show_planned_tasks_prompt()
func _show_planned_tasks_prompt() -> bool:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.80)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.z_index = 201
	add_child(center)

	var panel = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color("#2C2C2C")
	ps.corner_radius_top_left = 20
	ps.corner_radius_top_right = 20
	ps.corner_radius_bottom_left = 20
	ps.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var pm = MarginContainer.new()
	pm.add_theme_constant_override("margin_top", 40)
	pm.add_theme_constant_override("margin_bottom", 40)
	pm.add_theme_constant_override("margin_left", 50)
	pm.add_theme_constant_override("margin_right", 50)
	panel.add_child(pm)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 24)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	pm.add_child(vb)

	var title = Label.new()
	title.text = "📋 發現預先規劃的任務！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.set("theme_override_colors/font_color", Color.GOLD)
	vb.add_child(title)

	var desc = Label.new()
	desc.text = "你昨天已經預先規劃了今天的任務，\n要直接使用嗎？"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 20)
	desc.set("theme_override_colors/font_color", Color.WHITE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(380, 0)
	vb.add_child(desc)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)
	vb.add_child(btn_hbox)

	var yes_btn = Button.new()
	yes_btn.text = "✅ 使用規劃好的任務"
	yes_btn.custom_minimum_size = Vector2(220, 50)
	yes_btn.add_theme_font_size_override("font_size", 20)
	yes_btn.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	yes_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_hbox.add_child(yes_btn)

	var no_btn = Button.new()
	no_btn.text = "❌ 不用，重新規劃"
	no_btn.custom_minimum_size = Vector2(220, 50)
	no_btn.add_theme_font_size_override("font_size", 20)
	no_btn.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
	no_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_hbox.add_child(no_btn)

	yes_btn.pressed.connect(func(): _planned_choice_made.emit(true))
	no_btn.pressed.connect(func(): _planned_choice_made.emit(false))

	var result = await _planned_choice_made

	overlay.queue_free()
	center.queue_free()
	return result
