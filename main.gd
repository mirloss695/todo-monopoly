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

var cheat_panel: CheatPanel

func _ready():	
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	_setup_top_bar()

	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()

	todo_board.finish_btn.pressed.connect(_on_todo_finished)
	todo_board.request_save.connect(_on_todo_request_save)
	map_board.board_completed.connect(_on_map_completed)

	_load_from_save_manager()
	_check_new_day()
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
	
	print("💾 [Main] 存檔時 chance_tiles: ", map_board.chance_tiles)
	
	SaveManager.user_name               = profile_board.user_name
	SaveManager.reward_item             = profile_board.reward_item
	SaveManager.today_total_score  = todo_board.today_total_score
	SaveManager.current_day_tasks  = todo_board.serialize_tasks()
	SaveManager.is_day_locked      = not todo_board.is_editing
	SaveManager.is_day_finished    = (todo_board.finish_btn.text == "已結算")
	# 同步歷史紀錄
	SaveManager.task_history       = todo_board.task_history
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
	# 偵測到新的日曆日，自動推進遊戲天數
	print("📅 [Main] 偵測到新的一天（上次：%s，今天：%s），自動推進天數" % [SaveManager.last_played_date, today])
	global_day += 1
	_sync_all_data()
	todo_board.new_day_from_login()
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
