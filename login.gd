extends Control

var bg: ColorRect
var center_container: CenterContainer
var panel: PanelContainer
var title_label: Label
var email_input: LineEdit
var password_input: LineEdit
var login_btn: Button
var register_btn: Button
var status_label: Label

func _ready():
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
	vbox.add_theme_constant_override("separation", 25)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel_margin.add_child(vbox)
	
	# --- 標題 ---
	title_label = Label.new()
	title_label.text = "Todo Monopoly\n雲端連線系統"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.set("theme_override_colors/font_color", Color.GOLD)
	vbox.add_child(title_label)
	
	# --- 規則說明 ---
	var desc_label = Label.new()
	desc_label.text = "※ 請使用電子郵件與密碼登入\n※ 新玩家請點「註冊帳號」建立帳號"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.set("theme_override_colors/font_color", Color.GRAY)
	vbox.add_child(desc_label)
	
	# --- 電子郵件輸入框 ---
	email_input = LineEdit.new()
	email_input.placeholder_text = "請輸入電子郵件 (例: ken@example.com)"
	email_input.custom_minimum_size = Vector2(350, 50)
	email_input.add_theme_font_size_override("font_size", 18)
	email_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(email_input)
	
	# --- 密碼輸入框 ---
	password_input = LineEdit.new()
	password_input.placeholder_text = "請輸入密碼 (至少 8 個字元)"
	password_input.custom_minimum_size = Vector2(350, 50)
	password_input.add_theme_font_size_override("font_size", 18)
	password_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	password_input.secret = true  # 隱藏密碼顯示
	vbox.add_child(password_input)
	
	# --- 狀態提示文字 ---
	status_label = Label.new()
	status_label.text = "請輸入帳號密碼以進入遊戲"
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
	
	register_btn = Button.new()
	register_btn.text = "📝 註冊帳號"
	register_btn.custom_minimum_size = Vector2(160, 50)
	register_btn.add_theme_font_size_override("font_size", 20)
	register_btn.pressed.connect(_on_register_pressed)
	btn_hbox.add_child(register_btn)
	
	login_btn = Button.new()
	login_btn.text = "🚀 進入遊戲"
	login_btn.custom_minimum_size = Vector2(160, 50)
	login_btn.add_theme_font_size_override("font_size", 20)
	login_btn.pressed.connect(_on_login_pressed)
	btn_hbox.add_child(login_btn)

# ==========================================
# ☁️ 工具：停用 / 啟用按鈕
# ==========================================
func _set_buttons_disabled(disabled: bool):
	login_btn.disabled = disabled
	register_btn.disabled = disabled

# ==========================================
# 📝 註冊新帳號
# ==========================================
func _on_register_pressed():
	var email    = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email == "" or password == "":
		status_label.text = "❌ 電子郵件與密碼不可為空！"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
		return
	
	if password.length() < 8:
		status_label.text = "❌ 密碼至少需要 8 個字元！"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
		return
	
	status_label.text = "⏳ 正在建立帳號..."
	status_label.set("theme_override_colors/font_color", Color.YELLOW)
	_set_buttons_disabled(true)
	
	# 使用 White Label SignUp 建立新帳號
	var response = await LL_WhiteLabel.SignUp.new(email, password).send()
	
	_set_buttons_disabled(false)
	
	if response.success:
		status_label.text = "✅ 帳號建立成功！\n可直接登入。"
		status_label.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	else:
		status_label.text = "❌ 建立帳號失敗，該信箱可能已被使用"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)

# ==========================================
# 🚀 登入並開始遊戲
# ==========================================
func _on_login_pressed():
	var email    = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email == "" or password == "":
		status_label.text = "❌ 電子郵件與密碼不可為空！"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
		return
	
	status_label.text = "⏳ 正在連線至雲端伺服器..."
	status_label.set("theme_override_colors/font_color", Color.YELLOW)
	_set_buttons_disabled(true)
	
	# 使用 White Label LoginAndStartSession 一步完成登入與建立遊戲 Session
	var response = await LL_WhiteLabel.LoginAndStartSession.new(email, password).send()
	
	_set_buttons_disabled(false)
	
	if response.success:
		status_label.text = "✅ 連線成功！正在同步雲端進度..."
		status_label.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		
		# 呼叫 SaveManager 從 LootLocker 下載這名玩家的專屬進度
		await SaveManager.load_from_cloud()
		
		# 下載完成後，轉跳到主遊戲畫面
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		status_label.text = "❌ 登入失敗，請確認帳號密碼，\n或先至信箱完成驗證"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
