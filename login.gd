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
	bg = ColorRect.new()
	bg.color = Color("#1E1E1E")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
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
	
	title_label = Label.new()
	title_label.text = "Todo Monopoly\n雲端連線系統"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.set("theme_override_colors/font_color", Color.GOLD)
	vbox.add_child(title_label)
	
	var desc_label = Label.new()
	desc_label.text = "※ 請使用電子郵件與密碼登入\n※ 新玩家請點「註冊帳號」建立帳號"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.set("theme_override_colors/font_color", Color.GRAY)
	vbox.add_child(desc_label)
	
	email_input = LineEdit.new()
	email_input.placeholder_text = "請輸入電子郵件 (例: ken@example.com)"
	email_input.custom_minimum_size = Vector2(350, 50)
	email_input.add_theme_font_size_override("font_size", 18)
	email_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(email_input)
	
	password_input = LineEdit.new()
	password_input.placeholder_text = "請輸入密碼 (至少 8 個字元)"
	password_input.custom_minimum_size = Vector2(350, 50)
	password_input.add_theme_font_size_override("font_size", 18)
	password_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	password_input.secret = true
	vbox.add_child(password_input)
	
	status_label = Label.new()
	status_label.text = "請輸入帳號密碼以進入遊戲"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.set("theme_override_colors/font_color", Color.LIGHT_SKY_BLUE)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(350, 0)
	vbox.add_child(status_label)
	
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
	
	var response = await LL_WhiteLabel.SignUp.new(email, password).send()
	_set_buttons_disabled(false)
	
	if response.success:
		status_label.text = "✅ 帳號建立成功！\n請至信箱驗證後再登入。"
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
	
	var response = await LL_WhiteLabel.LoginAndStartSession.new(email, password).send()
	_set_buttons_disabled(false)
	
	if response.success:
		status_label.text = "✅ 連線成功！正在同步雲端進度..."
		status_label.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		
		# 【關鍵】把遊戲 session token 存到 SaveManager，供 REST API 使用
		# LoginAndStartSession 回傳的 session_token 是遊戲 session token
		SaveManager.session_token = response.session_token
		
		# load_from_cloud() 回傳 true = 老玩家有存檔，false = 新玩家
		var is_new_player = not await SaveManager.load_from_cloud()
		
		if is_new_player:
			await _show_new_player_setup()
		
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		status_label.text = "❌ 登入失敗，請確認帳號密碼，\n或先至信箱完成驗證"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)

# ==========================================
# 🎉 新玩家初始化設定視窗
# ==========================================
signal _setup_done

func _show_new_player_setup():
	# --- 遮罩背景 ---
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.80)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	add_child(overlay)
	
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.z_index = 201
	add_child(cc)
	
	# --- 面板 ---
	var setup_panel = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color("#2C2C2C")
	ps.corner_radius_top_left    = 20
	ps.corner_radius_top_right   = 20
	ps.corner_radius_bottom_left = 20
	ps.corner_radius_bottom_right = 20
	setup_panel.add_theme_stylebox_override("panel", ps)
	cc.add_child(setup_panel)
	
	var pm = MarginContainer.new()
	pm.add_theme_constant_override("margin_top",    50)
	pm.add_theme_constant_override("margin_bottom", 50)
	pm.add_theme_constant_override("margin_left",   60)
	pm.add_theme_constant_override("margin_right",  60)
	setup_panel.add_child(pm)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 28)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	pm.add_child(vb)
	
	# --- 歡迎標題 ---
	var title = Label.new()
	title.text = "🎉 歡迎來到 Todo Monopoly！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.set("theme_override_colors/font_color", Color.GOLD)
	vb.add_child(title)
	
	var sub = Label.new()
	sub.text = "請先設定你的玩家資料（可留空，之後可在帳號面板修改）"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 17)
	sub.set("theme_override_colors/font_color", Color.GRAY)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(420, 0)
	vb.add_child(sub)
	
	# --- 使用者名稱 ---
	var name_lbl = Label.new()
	name_lbl.text = "👤 你的玩家名稱"
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.set("theme_override_colors/font_color", Color.LIGHT_SKY_BLUE)
	vb.add_child(name_lbl)
	
	var name_edit = LineEdit.new()
	name_edit.placeholder_text = "留空則使用預設「新手玩家」"
	name_edit.custom_minimum_size = Vector2(420, 50)
	name_edit.add_theme_font_size_override("font_size", 20)
	vb.add_child(name_edit)
	
	# --- 獎勵目標 ---
	var reward_lbl = Label.new()
	reward_lbl.text = "🎁 最終想要的獎勵"
	reward_lbl.add_theme_font_size_override("font_size", 22)
	reward_lbl.set("theme_override_colors/font_color", Color.LIGHT_SKY_BLUE)
	vb.add_child(reward_lbl)
	
	var reward_edit = LineEdit.new()
	reward_edit.placeholder_text = "留空則使用預設「豪華大餐一頓」"
	reward_edit.custom_minimum_size = Vector2(420, 50)
	reward_edit.add_theme_font_size_override("font_size", 20)
	vb.add_child(reward_edit)
	
	# --- 確認按鈕 ---
	var confirm_btn = Button.new()
	confirm_btn.text = "✅ 確認，開始遊戲！"
	confirm_btn.custom_minimum_size = Vector2(260, 55)
	confirm_btn.add_theme_font_size_override("font_size", 22)
	confirm_btn.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	vb.add_child(confirm_btn)
	
	confirm_btn.pressed.connect(func():
		var n = name_edit.text.strip_edges()
		var r = reward_edit.text.strip_edges()
		SaveManager.user_name   = n if n != "" else "新手玩家"
		SaveManager.reward_item = r if r != "" else "豪華大餐一頓"
		# 立刻將初始資料存到雲端
		SaveManager.save_to_cloud()
		overlay.queue_free()
		cc.queue_free()
		_setup_done.emit()
	)
	
	await self._setup_done
