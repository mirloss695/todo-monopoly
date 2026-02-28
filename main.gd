extends Control

var global_score = 0
var global_day = 1
var global_stage = 1

@onready var todo_board = $TodoList
@onready var map_board = $MapBoard
@onready var profile_board = $UserProfile

var top_bar: HBoxContainer
var profile_btn: Button
var switch_btn: Button
var next_day_btn: Button

func _ready():
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# --- 頂部常駐按鈕列 (排版在左上角，並拉高層級) ---
	top_bar = HBoxContainer.new()
	top_bar.position = Vector2(20, 20)
	top_bar.add_theme_constant_override("separation", 20)
	top_bar.z_index = 90 # 浮在任務版塊之上，但被 Profile 蓋住
	add_child(top_bar)
	
	profile_btn = Button.new()
	profile_btn.text = "👤 帳號資料"
	profile_btn.custom_minimum_size = Vector2(160, 50)
	profile_btn.add_theme_font_size_override("font_size", 20)
	profile_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	profile_btn.pressed.connect(_on_profile_pressed)
	top_bar.add_child(profile_btn)
	
	# 【新增】自由切換版塊按鈕
	switch_btn = Button.new()
	switch_btn.text = "🗺️ 切換至地圖"
	switch_btn.custom_minimum_size = Vector2(180, 50)
	switch_btn.add_theme_font_size_override("font_size", 20)
	switch_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	switch_btn.pressed.connect(_on_switch_pressed)
	top_bar.add_child(switch_btn)
	
	# --- 右下角「下一天」按鈕 ---
	next_day_btn = Button.new()
	next_day_btn.text = "🌙 結束今天，進入下一天"
	next_day_btn.custom_minimum_size = Vector2(260, 60)
	next_day_btn.add_theme_font_size_override("font_size", 22)
	next_day_btn.set("theme_override_colors/font_color", Color.AQUAMARINE)
	next_day_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_day_btn.pressed.connect(_on_next_day_pressed)
	add_child(next_day_btn)
	next_day_btn.hide()
	
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()
	
	todo_board.finish_btn.pressed.connect(_on_todo_finished)
	
	sync_all_data()
	map_board.hide()
	profile_board.hide()
	todo_board.show()

func _on_window_resized():
	var screen_size = get_viewport_rect().size
	if next_day_btn:
		next_day_btn.position = screen_size - next_day_btn.size - Vector2(40, 40)

func sync_all_data():
	todo_board.total_accumulated_score = global_score
	todo_board.current_stage = global_stage
	todo_board.update_score_display()
	
	map_board.total_score = global_score
	map_board.current_stage = global_stage
	
	profile_board.total_score = global_score
	profile_board.current_stage = global_stage
	profile_board.play_days = global_day
	profile_board.update_display()

# --- 點擊：帳號按鈕 ---
func _on_profile_pressed():
	if todo_board.visible: global_score = todo_board.total_accumulated_score
	elif map_board.visible: global_score = map_board.total_score
	sync_all_data()
	profile_board.show()

# --- 點擊：切換版塊按鈕 ---
func _on_switch_pressed():
	if todo_board.visible:
		# 檢查是否有未儲存的變更
		if todo_board.is_editing:
			todo_board.warning_dialog.dialog_text = "⚠️ 請先點擊「確認儲存」\n儲存變更後才能切換至地圖板塊！"
			todo_board.warning_dialog.popup_centered()
			return
			
		# 切換到地圖 (純觀看模式，不開啟骰子)
		todo_board.hide()
		map_board.show()
		switch_btn.text = "📝 切換回任務"
	else:
		# 切換回任務
		map_board.hide()
		todo_board.show()
		switch_btn.text = "🗺️ 切換至地圖"

# --- 點擊：任務結算 (正式進入骰子階段) ---
func _on_todo_finished():
	global_score = todo_board.total_accumulated_score
	sync_all_data()
	
	todo_board.hide()
	map_board.show()
	switch_btn.text = "📝 切換回任務"
	
	# 【修改】自動喚起地圖的「擲骰子」按鈕
	map_board.activate_dice()
	next_day_btn.show()

# --- 點擊：進入下一天 ---
func _on_next_day_pressed():
	global_score = map_board.total_score
	global_day += 1 
	sync_all_data()
	
	map_board.hide()
	next_day_btn.hide()
	switch_btn.text = "🗺️ 切換至地圖"
	
	if todo_board.has_method("reset_for_new_day"):
		todo_board.reset_for_new_day()
		
	todo_board.show()
