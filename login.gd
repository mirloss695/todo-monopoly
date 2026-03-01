extends Control

var bg: ColorRect
var center_container: CenterContainer
var panel: PanelContainer
var title_label: Label
var user_input: LineEdit
var pass_input: LineEdit
var login_btn: Button
var register_btn: Button
var status_label: Label

func _ready():
	# ==========================================
	# 🐺 初始化 SilentWolf 雲端連線
	# ==========================================
	SilentWolf.configure({
		"api_key": "sTlIRSyPGP9DUpQMcQmeH6hUQm1c052S8rachkrT",
		"game_id": "todomonopoly",
		"log_level": 1
	})
	
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	setup_ui()

func setup_ui():
	# --- 1. 背景 ---
	bg = ColorRect.new()
	bg.color = Color("#1E1E1E")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# --- 2. 完美置中容器 ---
	center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	# --- 3. 自動包覆面板 ---
	panel = PanelContainer.new()
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
	
	# --- 內部邊距 ---
	var panel_margin = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_top", 50)
	panel_margin.add_theme_constant_override("margin_bottom", 50)
	panel_margin.add_theme_constant_override("margin_left", 60)
	panel_margin.add_theme_constant_override("margin_right", 60)
	panel.add_child(panel_margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20) # 稍微縮小一點間距來放提示字
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel_margin.add_child(vbox)
	
	# --- 標題 ---
	title_label = Label.new()
	title_label.text = "Todo Monopoly\n登入系統"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.set("theme_override_colors/font_color", Color.GOLD)
	vbox.add_child(title_label)
	
	# --- 輸入框 ---
	user_input = LineEdit.new()
	user_input.placeholder_text = "請輸入玩家名稱"
	user_input.custom_minimum_size = Vector2(350, 50)
	user_input.add_theme_font_size_override("font_size", 20)
	vbox.add_child(user_input)
	
	pass_input = LineEdit.new()
	pass_input.placeholder_text = "請設定密碼"
	pass_input.custom_minimum_size = Vector2(350, 50)
	pass_input.add_theme_font_size_override("font_size", 20)
	pass_input.secret = true 
	vbox.add_child(pass_input)
	
	# --- 【新增】密碼規則提示文字 ---
	var rule_label = Label.new()
	rule_label.text = "※ 密碼需至少 8 碼，包含大小寫字母、數字與特殊符號"
	rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule_label.add_theme_font_size_override("font_size", 14)
	rule_label.set("theme_override_colors/font_color", Color.GRAY)
	rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_label.custom_minimum_size = Vector2(350, 0) 
	vbox.add_child(rule_label)
	
	# --- 狀態提示文字 ---
	status_label = Label.new()
	status_label.text = "請登入或註冊新帳號"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.set("theme_override_colors/font_color", Color.LIGHT_SKY_BLUE)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(350, 0) 
	vbox.add_child(status_label)
	
	# --- 按鈕區 ---
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	login_btn = Button.new()
	login_btn.text = "🚪 登入"
	login_btn.custom_minimum_size = Vector2(150, 50)
	login_btn.add_theme_font_size_override("font_size", 22)
	login_btn.pressed.connect(_on_login_pressed)
	btn_hbox.add_child(login_btn)
	
	register_btn = Button.new()
	register_btn.text = "📝 註冊"
	register_btn.custom_minimum_size = Vector2(150, 50)
	register_btn.add_theme_font_size_override("font_size", 22)
	register_btn.pressed.connect(_on_register_pressed)
	btn_hbox.add_child(register_btn)

# ==========================================
# ☁️ SilentWolf 雲端連線邏輯
# ==========================================

func _on_register_pressed():
	var player_name = user_input.text.strip_edges()
	var player_password = pass_input.text
	
	if player_name == "" or player_password == "":
		status_label.text = "❌ 帳號與密碼皆不可為空！"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
		return
		
	# 【新增】本地端先檢查長度，避免無效的網路等待
	if player_password.length() < 8:
		status_label.text = "❌ 密碼長度不足 8 碼！請參考上方規則。"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
		return
		
	status_label.text = "⏳ 正在向雲端註冊帳號中..."
	status_label.set("theme_override_colors/font_color", Color.YELLOW)
	
	SilentWolf.Auth.register_player(player_name, "", player_password, player_password)
	var sw_result = await SilentWolf.Auth.sw_registration_complete
	
	if sw_result.success:
		status_label.text = "✅ 註冊成功！請點擊登入。"
		status_label.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	else:
		# 即使出錯，也有自動換行保護，不怕撐破版面
		status_label.text = "❌ 註冊失敗：" + str(sw_result.error)
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)

func _on_login_pressed():
	var player_name = user_input.text.strip_edges()
	var player_password = pass_input.text
	
	if player_name == "" or player_password == "":
		status_label.text = "❌ 請輸入帳號與密碼！"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
		return
		
	status_label.text = "⏳ 正在驗證雲端帳號中..."
	status_label.set("theme_override_colors/font_color", Color.YELLOW)
	
	SilentWolf.Auth.login_player(player_name, player_password)
	var sw_result = await SilentWolf.Auth.sw_login_complete
	
	if sw_result.success:
		status_label.text = "✅ 登入成功！準備進入遊戲..."
		status_label.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		status_label.text = "❌ 登入失敗：帳號或密碼錯誤"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
