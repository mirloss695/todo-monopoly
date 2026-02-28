extends Control

# --- 模擬的全域變數 ---
var user_name = "新手玩家"
var total_score = 1500
var current_stage = 1
var move_direction = 1 
var play_days = 1
var reward_item = "豪華大餐一頓"

# --- UI 節點參考 ---
var overlay_bg: ColorRect
var panel: Panel
var avatar_btn: TextureButton 
var file_dialog: FileDialog
var name_input: LineEdit
var score_label: Label
var stage_label: RichTextLabel 
var date_label: Label
var days_label: Label
var reward_prefix_label: Label
var reward_input: LineEdit
var close_btn: Button

func _ready():
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	# 【修改 1】強制拉高圖層，保證蓋過地圖棋子 (棋子為 10)
	self.z_index = 100 
	get_viewport().size_changed.connect(_on_window_resized)
	
	setup_ui()
	update_display()

func _on_window_resized():
	var screen_size = get_viewport_rect().size
	if overlay_bg:
		overlay_bg.size = screen_size
	if panel:
		panel.position = (screen_size - panel.size) / 2.0

func setup_ui():
	overlay_bg = ColorRect.new()
	overlay_bg.color = Color(0, 0, 0, 0.75)
	add_child(overlay_bg)
	
	panel = Panel.new()
	panel.size = Vector2(850, 620) 
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2C2C2C")
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 15
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(header_hbox)
	
	var avatar_placeholder = Control.new()
	avatar_placeholder.custom_minimum_size = Vector2(45, 45) 
	
	var avatar_size = 80 
	var avatar_bg = Panel.new()
	avatar_bg.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW 
	avatar_bg.size = Vector2(avatar_size, avatar_size)
	avatar_bg.position = Vector2((45 - avatar_size) / 2.0, (45 - avatar_size) / 2.0)
	
	var avatar_style = StyleBoxFlat.new()
	avatar_style.bg_color = Color("#444444")
	avatar_style.corner_radius_top_left = 40
	avatar_style.corner_radius_top_right = 40
	avatar_style.corner_radius_bottom_left = 40
	avatar_style.corner_radius_bottom_right = 40
	avatar_bg.add_theme_stylebox_override("panel", avatar_style)
	
	var default_avatar_lbl = Label.new()
	default_avatar_lbl.text = "頭"
	default_avatar_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	default_avatar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	default_avatar_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	default_avatar_lbl.add_theme_font_size_override("font_size", 24)
	default_avatar_lbl.set("theme_override_colors/font_color", Color.GRAY)
	avatar_bg.add_child(default_avatar_lbl)
	
	avatar_btn = TextureButton.new()
	avatar_btn.ignore_texture_size = true
	avatar_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	avatar_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var default_tex = load("res://default_avatar.png")
	if default_tex:
		avatar_btn.texture_normal = default_tex
		
	avatar_btn.pressed.connect(_on_change_avatar_pressed)
	avatar_bg.add_child(avatar_btn)
	avatar_placeholder.add_child(avatar_bg)
	header_hbox.add_child(avatar_placeholder)
	
	var title = Label.new()
	title.text = "帳號" 
	title.add_theme_font_size_override("font_size", 36) 
	title.set("theme_override_colors/font_color", Color.GOLD)
	header_hbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var grid = GridContainer.new()
	grid.columns = 3 
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 20)
	vbox.add_child(grid)
	
	name_input = LineEdit.new()
	name_input.text = user_name
	name_input.add_theme_font_size_override("font_size", 24)
	name_input.text_changed.connect(_on_name_changed)
	_add_grid_row(grid, "▹ 使用者名稱", name_input)
	
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 24)
	_add_grid_row(grid, "▹ 目前累積得分", score_label)
	
	stage_label = RichTextLabel.new() 
	stage_label.bbcode_enabled = true
	stage_label.fit_content = true
	stage_label.add_theme_font_size_override("normal_font_size", 24)
	_add_grid_row(grid, "▹ 目前階段狀況", stage_label)
	
	date_label = Label.new()
	date_label.add_theme_font_size_override("font_size", 24)
	_add_grid_row(grid, "▹ 今天日期", date_label)
	
	days_label = Label.new()
	days_label.add_theme_font_size_override("font_size", 24)
	_add_grid_row(grid, "▹ 累計遊玩天數", days_label)
	
	var reward_hbox = HBoxContainer.new()
	reward_hbox.add_theme_constant_override("separation", 10)
	
	reward_prefix_label = Label.new()
	reward_prefix_label.add_theme_font_size_override("font_size", 24)
	reward_prefix_label.set("theme_override_colors/font_color", Color.PALE_VIOLET_RED)
	reward_hbox.add_child(reward_prefix_label)
	
	reward_input = LineEdit.new()
	reward_input.text = reward_item
	reward_input.size_flags_horizontal = SIZE_EXPAND_FILL
	reward_input.add_theme_font_size_override("font_size", 24)
	reward_input.placeholder_text = "請輸入您想要的獎勵"
	reward_input.text_changed.connect(_on_reward_changed)
	reward_hbox.add_child(reward_input)
	
	_add_grid_row(grid, "▹ 終點獎勵目標", reward_hbox)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)
	
	close_btn = Button.new()
	close_btn.text = "關閉"
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
	close_btn.custom_minimum_size = Vector2(250, 60) 
	
	var flat_style = StyleBoxFlat.new()
	flat_style.bg_color = Color(0.2, 0.2, 0.2)
	flat_style.corner_radius_top_left = 10
	flat_style.corner_radius_top_right = 10
	flat_style.corner_radius_bottom_left = 10
	flat_style.corner_radius_bottom_right = 10
	close_btn.add_theme_stylebox_override("normal", flat_style)
	close_btn.pressed.connect(_on_close_pressed)
	btn_hbox.add_child(close_btn)
	
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg"])
	file_dialog.use_native_dialog = true 
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)

func _add_grid_row(grid: GridContainer, title_text: String, content_node: Control):
	var t_lbl = Label.new()
	t_lbl.text = title_text
	t_lbl.add_theme_font_size_override("font_size", 24)
	t_lbl.set("theme_override_colors/font_color", Color.LIGHT_SKY_BLUE)
	grid.add_child(t_lbl)
	
	var colon_lbl = Label.new()
	colon_lbl.text = "："
	colon_lbl.add_theme_font_size_override("font_size", 24)
	colon_lbl.set("theme_override_colors/font_color", Color.LIGHT_SKY_BLUE)
	grid.add_child(colon_lbl)
	
	content_node.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.add_child(content_node)

func update_display():
	score_label.text = str(total_score) + " 分"
	var direction_text = "靠近" if move_direction == 1 else "遠離"
	var highlight_color = "#32CD32" if move_direction == 1 else "#FF4500" 
	stage_label.text = "現在是階段 %d，您正在 [color=%s]%s[/color] 蟲洞" % [current_stage, highlight_color, direction_text]
	
	var time = Time.get_date_dict_from_system()
	date_label.text = "%d 年 %02d 月 %02d 日" % [time.year, time.month, time.day]
	days_label.text = "您已經進行了 %d 天" % play_days
	
	var prefix = ""
	match current_stage:
		1: prefix = "遠在天邊的"
		2: prefix = "一點一點靠近的"
		3: prefix = "就快要抵達了的"
		_: prefix = "未知的"
	reward_prefix_label.text = prefix

func _on_name_changed(new_text: String): user_name = new_text
func _on_reward_changed(new_text: String): reward_item = new_text
func _on_change_avatar_pressed(): file_dialog.popup_centered(Vector2(600, 400)) 

func _on_file_selected(path: String):
	var image = Image.new()
	if image.load(path) == OK:
		avatar_btn.texture_normal = ImageTexture.create_from_image(image)

func _on_close_pressed():
	self.hide() 
	
# 【修改 2】已移除 _input 事件，Tab 鍵不再會叫出畫面
