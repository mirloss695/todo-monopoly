extends Control

var global_score = 0
var global_day = 1
var global_stage = 1

@onready var todo_board = $TodoList
@onready var map_board = $MapBoard
@onready var profile_board = $UserProfile

var top_bar: VBoxContainer 
var profile_btn: Button
var switch_btn: Button
var next_day_btn: Button

var is_board_finished = false
var is_on_map = false
var is_switch_hovered = false
var is_map_completed = false 

func _ready():
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	top_bar = VBoxContainer.new() 
	top_bar.position = Vector2(20, 20)
	top_bar.add_theme_constant_override("separation", 15) 
	top_bar.z_index = 90 
	add_child(top_bar)
	
	profile_btn = Button.new()
	profile_btn.text = "👤"
	profile_btn.custom_minimum_size = Vector2(50, 50)
	profile_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN 
	profile_btn.add_theme_font_size_override("font_size", 20)
	profile_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	profile_btn.pressed.connect(_on_profile_pressed)
	profile_btn.mouse_entered.connect(func(): profile_btn.text = "👤 帳號資料")
	profile_btn.mouse_exited.connect(func(): profile_btn.text = "👤")
	top_bar.add_child(profile_btn)
	
	switch_btn = Button.new()
	switch_btn.text = "🗺️"
	switch_btn.custom_minimum_size = Vector2(50, 50)
	switch_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN 
	switch_btn.add_theme_font_size_override("font_size", 20)
	switch_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	switch_btn.pressed.connect(_on_switch_pressed)
	switch_btn.mouse_entered.connect(func(): 
		is_switch_hovered = true
		update_switch_btn_text()
	)
	switch_btn.mouse_exited.connect(func(): 
		is_switch_hovered = false
		update_switch_btn_text()
	)
	top_bar.add_child(switch_btn)
	
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
	map_board.board_completed.connect(_on_map_completed) 
	
	sync_all_data()
	map_board.hide()
	profile_board.hide()
	todo_board.show()

func update_switch_btn_text():
	if is_switch_hovered:
		switch_btn.text = "📝 切換回任務" if is_on_map else "🗺️ 切換至地圖"
	else:
		switch_btn.text = "📝" if is_on_map else "🗺️"

func _on_window_resized():
	var screen_size = get_viewport_rect().size
	# 【關鍵修復】拿掉會干擾 Godot 原生 Anchor 的手動尺寸設定
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

func _on_profile_pressed():
	if todo_board.visible: global_score = todo_board.total_accumulated_score
	elif map_board.visible: global_score = map_board.total_score
	sync_all_data()
	profile_board.show()

func _on_switch_pressed():
	if not is_on_map: 
		if todo_board.is_editing:
			todo_board.warning_dialog.dialog_text = "⚠️ 請先點擊「確認儲存」\n儲存變更後才能切換至地圖板塊！"
			todo_board.warning_dialog.popup_centered()
			return
		is_on_map = true
		todo_board.hide()
		map_board.show()
		
		if is_map_completed:
			next_day_btn.show()
		else:
			next_day_btn.hide()
	else: 
		is_on_map = false
		map_board.hide()
		next_day_btn.hide() 
		todo_board.show()
	
	update_switch_btn_text()

func _on_todo_finished():
	global_score = todo_board.total_accumulated_score
	is_board_finished = true 
	sync_all_data()
	
	is_on_map = true
	todo_board.hide()
	map_board.show()
	update_switch_btn_text()
	
	map_board.activate_dice()

func _on_map_completed():
	is_map_completed = true
	if is_on_map:
		next_day_btn.show()

func _on_next_day_pressed():
	global_score = map_board.total_score
	global_day += 1 
	is_board_finished = false
	is_on_map = false
	is_map_completed = false 
	sync_all_data()
	
	map_board.hide()
	next_day_btn.hide()
	update_switch_btn_text()
	
	if todo_board.has_method("reset_for_new_day"):
		todo_board.reset_for_new_day()
		
	todo_board.show()
