extends Control

var bg: ColorRect
var main_vbox: VBoxContainer
var title_label: Label
var username_input: LineEdit
var password_input: LineEdit
var login_btn: Button
var register_btn: Button
var status_label: Label

const EMAIL_SUFFIX = "@yourgame.local"

func _ready():
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	setup_ui()

func setup_ui():
	bg = ColorRect.new()
	bg.color = Color("#2C2C2C")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 500)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#3A3A3A")
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("margin_top", 40)
	main_vbox.add_theme_constant_override("margin_left", 40)
	main_vbox.add_theme_constant_override("margin_right", 40)
	main_vbox.add_theme_constant_override("separation", 20)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	panel.add_child(margin)
	margin.add_child(main_vbox)
	
	title_label = Label.new()
	title_label.text = "遊戲登入"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.set("theme_override_colors/font_color", Color.GOLD)
	main_vbox.add_child(title_label)
	
	main_vbox.add_child(HSeparator.new())
	
	username_input = LineEdit.new()
	username_input.placeholder_text = "請輸入帳號 (Username)"
	username_input.add_theme_font_size_override("font_size", 20)
	username_input.custom_minimum_size = Vector2(0, 45)
	main_vbox.add_child(username_input)
	
	password_input = LineEdit.new()
	password_input.placeholder_text = "請輸入密碼"
	password_input.secret = true 
	password_input.add_theme_font_size_override("font_size", 20)
	password_input.custom_minimum_size = Vector2(0, 45)
	main_vbox.add_child(password_input)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(spacer)
	
	login_btn = Button.new()
	login_btn.text = "登入"
	login_btn.add_theme_font_size_override("font_size", 24)
	login_btn.custom_minimum_size = Vector2(0, 50)
	login_btn.pressed.connect(_on_login_pressed)
	main_vbox.add_child(login_btn)
	
	register_btn = Button.new()
	register_btn.text = "註冊新帳號"
	register_btn.add_theme_font_size_override("font_size", 20)
	register_btn.set("theme_override_colors/font_color", Color.LIGHT_SKY_BLUE)
	register_btn.flat = true 
	register_btn.pressed.connect(_on_register_pressed)
	main_vbox.add_child(register_btn)
	
	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
	main_vbox.add_child(status_label)

func validate_inputs() -> bool:
	if username_input.text.strip_edges() == "":
		status_label.text = "請輸入帳號！"
		return false
	if password_input.text.length() < 6:
		status_label.text = "密碼長度至少需要 6 個字元！"
		return false
	return true

# --- 註冊與登入邏輯 (官方標準寫法) ---
func _on_register_pressed():
	if not validate_inputs(): return
	
	status_label.text = "註冊中，請稍候..."
	var pseudo_email = username_input.text.strip_edges() + EMAIL_SUFFIX
	var password = password_input.text
	
	LootLocker.white_label_sign_up(pseudo_email, password, Callable(self, "_on_signup_completed"))

func _on_signup_completed(response):
	if response.success:
		status_label.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		status_label.text = "註冊成功！自動登入中..."
		_on_login_pressed()
	else:
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
		status_label.text = "註冊失敗，帳號可能已被使用。"

func _on_login_pressed():
	if not validate_inputs(): return
	
	status_label.text = "登入中，請稍候..."
	var pseudo_email = username_input.text.strip_edges() + EMAIL_SUFFIX
	var password = password_input.text
	
	# 參數：email, password, remember_me, callback
	LootLocker.white_label_login(pseudo_email, password, true, Callable(self, "_on_login_completed"))

func _on_login_completed(response):
	if response.success:
		status_label.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		status_label.text = "登入成功！載入遊戲..."
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
		status_label.text = "登入失敗，請檢查帳號密碼。"
