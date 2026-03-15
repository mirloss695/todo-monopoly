class_name LoginUIBuilder
## 負責建構登入畫面所有 UI 元件

static func build(host: Control) -> Dictionary:
	var refs := {}

	var bg = ColorRect.new()
	bg.color = Color("#1E1E1E")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)

	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(center_container)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2C2C2C")
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 15
	panel.add_theme_stylebox_override("panel", style)
	center_container.add_child(panel)

	var panel_margin = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_top", 50)
	panel_margin.add_theme_constant_override("margin_bottom", 50)
	panel_margin.add_theme_constant_override("margin_left", 60)
	panel_margin.add_theme_constant_override("margin_right", 60)
	panel.add_child(panel_margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel_margin.add_child(vbox)

	# --- 標題 ---
	var title_label = Label.new()
	title_label.text = "Todo Monopoly\n註冊/登入"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.set("theme_override_colors/font_color", Color.GOLD)
	vbox.add_child(title_label)

	var desc_label = Label.new()
	desc_label.text = "※ 請使用帳號與密碼登入\n※ 新玩家請點「註冊帳號」建立帳號"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.set("theme_override_colors/font_color", Color.GRAY)
	vbox.add_child(desc_label)

	# --- 輸入框 ---
	var email_input = LineEdit.new()
	email_input.placeholder_text = "請輸入帳號"
	email_input.custom_minimum_size = Vector2(350, 50)
	email_input.add_theme_font_size_override("font_size", 18)
	email_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(email_input)
	refs["email_input"] = email_input

	var password_input = LineEdit.new()
	password_input.placeholder_text = "請輸入密碼 (至少 8 個字元)"
	password_input.custom_minimum_size = Vector2(350, 50)
	password_input.add_theme_font_size_override("font_size", 18)
	password_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	password_input.secret = true
	vbox.add_child(password_input)
	refs["password_input"] = password_input

	# --- 狀態標籤 ---
	var status_label = Label.new()
	status_label.text = "請輸入帳號密碼以進入遊戲"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.set("theme_override_colors/font_color", Color.LIGHT_SKY_BLUE)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(350, 0)
	vbox.add_child(status_label)
	refs["status_label"] = status_label

	# --- 按鈕列 ---
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)

	var register_btn = Button.new()
	register_btn.text = "📝 註冊帳號"
	register_btn.custom_minimum_size = Vector2(160, 50)
	register_btn.add_theme_font_size_override("font_size", 20)
	btn_hbox.add_child(register_btn)
	refs["register_btn"] = register_btn

	var login_btn = Button.new()
	login_btn.text = "🚀 進入遊戲"
	login_btn.custom_minimum_size = Vector2(160, 50)
	login_btn.add_theme_font_size_override("font_size", 20)
	btn_hbox.add_child(login_btn)
	refs["login_btn"] = login_btn

	return refs
