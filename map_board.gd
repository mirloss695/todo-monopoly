extends Node2D

signal user_confirmed

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

func _ready():
	randomize()
	
	bg = ColorRect.new()
	bg.color = Color("#EDE9E3")
	add_child(bg)
	
	map_root = Node2D.new()
	add_child(map_root)
	
	get_viewport().size_changed.connect(_on_window_resized)
	# 【修復 Bug】讓 CanvasLayer UI 跟隨 MapBoard 一起顯示/隱藏
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
	if map_root:
		var map_size = Vector2(510, 510) 
		map_root.position = (screen_size - map_size) / 2.0
	if event_panel:
		event_panel.position = (screen_size - event_panel.size) / 2.0
	if roll_dice_btn:
		# 【修改】將擲骰子按鈕往畫面中間靠攏 (0.55 代表畫面垂直 55% 的位置)
		roll_dice_btn.position = Vector2((screen_size.x - 250) / 2.0, screen_size.y * 0.55)

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
		if i == 0: label.text = "開始⮕"
		elif i == spiral_path.size() - 1: label.text = "蟲洞"
		elif i in chance_tiles: label.text = "機會與\n命運"
		else: label.text = str(i)
			
		label.set("theme_override_colors/font_color", Color.WHITE if i in chance_tiles else Color.BLACK)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT) 
		label.add_theme_font_size_override("font_size", 24) 
		tile.add_child(label)
		map_tiles.append(tile)

func create_player():
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
	
	player_node.position = map_tiles[0].position + (tile_size - player_node.size) / 2.0
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
		is_event_active = false
	elif current_tile_index in chance_tiles:
		show_chance_wheel() 
	else:
		is_event_active = false 

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
		3: total_score += m; is_event_active = false
		4: total_score -= m; is_event_active = false

func _input(event):
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		if is_waiting_confirm:
			is_waiting_confirm = false
			user_confirmed.emit()
