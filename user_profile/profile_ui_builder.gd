class_name ProfileUIBuilder
## 負責建構帳號面板的所有 UI 元件

static func build(host: Control) -> Dictionary:
	var refs := {}

	# --- 遮罩背景 ---
	var overlay_bg = ColorRect.new()
	overlay_bg.color = Color(0, 0, 0, 0.85)
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(overlay_bg)

	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(center_container)

	# --- 面板 ---
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(850, 620)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2C2C2C")
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 15
	panel.add_theme_stylebox_override("panel", style)
	center_container.add_child(panel)

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

	# --- 頭像 + 標題 ---
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(header_hbox)

	var avatar_btn = _build_avatar(header_hbox)
	refs["avatar_btn"] = avatar_btn

	var title = Label.new()
	title.text = "帳號"
	title.add_theme_font_size_override("font_size", 36)
	title.set("theme_override_colors/font_color", Color.GOLD)
	header_hbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# --- 資料 Grid ---
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 20)
	vbox.add_child(grid)

	var name_input = LineEdit.new()
	name_input.add_theme_font_size_override("font_size", 24)
	_add_grid_row(grid, "▹ 使用者名稱", name_input)
	refs["name_input"] = name_input

	var score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 24)
	_add_grid_row(grid, "▹ 目前累積得分", score_label)
	refs["score_label"] = score_label

	var stage_label = RichTextLabel.new()
	stage_label.bbcode_enabled = true
	stage_label.fit_content = true
	stage_label.add_theme_font_size_override("normal_font_size", 24)
	_add_grid_row(grid, "▹ 目前階段狀況", stage_label)
	refs["stage_label"] = stage_label

	var date_label = Label.new()
	date_label.add_theme_font_size_override("font_size", 24)
	_add_grid_row(grid, "▹ 今天日期", date_label)
	refs["date_label"] = date_label

	var days_label = Label.new()
	days_label.add_theme_font_size_override("font_size", 24)
	_add_grid_row(grid, "▹ 累計遊玩天數", days_label)
	refs["days_label"] = days_label

	# --- 獎勵目標列 ---
	var reward_hbox = HBoxContainer.new()
	reward_hbox.add_theme_constant_override("separation", 10)

	var reward_prefix_label = Label.new()
	reward_prefix_label.add_theme_font_size_override("font_size", 24)
	reward_prefix_label.set("theme_override_colors/font_color", Color.PALE_VIOLET_RED)
	reward_hbox.add_child(reward_prefix_label)
	refs["reward_prefix_label"] = reward_prefix_label

	var reward_input = LineEdit.new()
	reward_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_input.add_theme_font_size_override("font_size", 24)
	reward_input.placeholder_text = "請輸入您想要的獎勵"
	reward_hbox.add_child(reward_input)
	refs["reward_input"] = reward_input

	_add_grid_row(grid, "▹ 終點獎勵目標", reward_hbox)

	# --- 彈性空間 ---
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# --- 關閉按鈕 ---
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	var close_btn = Button.new()
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
	btn_hbox.add_child(close_btn)
	refs["close_btn"] = close_btn

	# --- 檔案對話框 ---
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg"])
	file_dialog.use_native_dialog = true
	host.add_child(file_dialog)
	refs["file_dialog"] = file_dialog

	return refs

# ── 內部工具 ──

static func _build_avatar(parent: HBoxContainer) -> TextureButton:
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

	var avatar_btn = TextureButton.new()
	avatar_btn.ignore_texture_size = true
	avatar_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	avatar_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var default_tex = load("res://default_avatar.png")
	if default_tex:
		avatar_btn.texture_normal = default_tex

	avatar_bg.add_child(avatar_btn)
	avatar_placeholder.add_child(avatar_bg)
	parent.add_child(avatar_placeholder)

	return avatar_btn

static func _add_grid_row(grid: GridContainer, title_text: String, content_node: Control):
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

	content_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(content_node)
