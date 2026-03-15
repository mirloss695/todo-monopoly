extends Control
## 登入畫面主控制器
## UI 建構委託給 LoginUIBuilder
## 新玩家設定委託給 NewPlayerSetup

var email_input: LineEdit
var password_input: LineEdit
var login_btn: Button
var register_btn: Button
var status_label: Label

func _ready():
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	_setup_ui()

func _setup_ui():
	var refs = LoginUIBuilder.build(self)

	email_input    = refs["email_input"]
	password_input = refs["password_input"]
	login_btn      = refs["login_btn"]
	register_btn   = refs["register_btn"]
	status_label   = refs["status_label"]

	register_btn.pressed.connect(_on_register_pressed)
	login_btn.pressed.connect(_on_login_pressed)

# ==========================================
# 工具：狀態更新 & 按鈕啟停
# ==========================================
func _set_status(text: String, color: Color):
	status_label.text = text
	status_label.set("theme_override_colors/font_color", color)

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
		_set_status("❌ 帳號與密碼不可為空！", Color.LIGHT_CORAL)
		return

	if password.length() < 8:
		_set_status("❌ 密碼至少需要 8 個字元！", Color.LIGHT_CORAL)
		return

	_set_status("⏳ 正在建立帳號...", Color.YELLOW)
	_set_buttons_disabled(true)

	var response = await LL_WhiteLabel.SignUp.new(email, password).send()
	_set_buttons_disabled(false)

	if response.success:
		_set_status("✅ 帳號建立成功！", Color.GREEN_YELLOW)
	else:
		_set_status("❌ 建立帳號失敗，該帳號可能已被使用", Color.LIGHT_CORAL)

# ==========================================
# 🚀 登入並開始遊戲
# ==========================================
func _on_login_pressed():
	var email    = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()

	if email == "" or password == "":
		_set_status("❌ 帳號與密碼不可為空！", Color.LIGHT_CORAL)
		return

	_set_status("⏳ 正在連線至雲端伺服器...", Color.YELLOW)
	_set_buttons_disabled(true)

	var response = await LL_WhiteLabel.LoginAndStartSession.new(email, password).send()
	_set_buttons_disabled(false)

	if response.success:
		_set_status("✅ 連線成功！正在同步雲端進度...", Color.GREEN_YELLOW)

		SaveManager.session_token = response.session_token
		var is_new_player = not await SaveManager.load_from_cloud()

		if is_new_player:
			await NewPlayerSetup.new().show_on(self)

		get_tree().change_scene_to_file("res://main.tscn")
	else:
		_set_status("❌ 登入失敗，請確認帳號密碼，\n未註冊玩家請先註冊", Color.LIGHT_CORAL)
