extends Control

var bg: ColorRect
var center_container: CenterContainer
var panel: PanelContainer
var title_label: Label
var user_input: LineEdit
var login_btn: Button
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
	desc_label.text = "※ 第一次輸入代號會自動建立新帳號\n※ 之後輸入相同代號即可接續遊玩"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.set("theme_override_colors/font_color", Color.GRAY)
	vbox.add_child(desc_label)
	
	# --- 專屬代號輸入框 ---
	user_input = LineEdit.new()
	user_input.placeholder_text = "請輸入你的專屬代號 (例: Ken_001)"
	user_input.custom_minimum_size = Vector2(350, 50)
	user_input.add_theme_font_size_override("font_size", 20)
	user_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(user_input)
	
	# --- 狀態提示文字 ---
	status_label = Label.new()
	status_label.text = "請輸入代號以進入遊戲"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.set("theme_override_colors/font_color", Color.LIGHT_SKY_BLUE)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(350, 0) 
	vbox.add_child(status_label)
	
	# --- 按鈕區 ---
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)
	
	login_btn = Button.new()
	login_btn.text = "🚀 進入遊戲"
	login_btn.custom_minimum_size = Vector2(200, 50)
	login_btn.add_theme_font_size_override("font_size", 22)
	login_btn.pressed.connect(_on_login_pressed)
	btn_hbox.add_child(login_btn)

# ==========================================
# ☁️ LootLocker 雲端連線邏輯
# ==========================================
func _on_login_pressed():
	var player_identifier = user_input.text.strip_edges()
	
	if player_identifier == "":
		status_label.text = "❌ 代號不可為空！"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
		return
		
	status_label.text = "⏳ 正在連線至雲端伺服器..."
	status_label.set("theme_override_colors/font_color", Color.YELLOW)
	login_btn.disabled = true # 防止玩家瘋狂連點
	
	# 【關鍵修復】使用 LootLocker Godot 4 SDK 的最新物件導向語法
	var response = await LL_Authentication.GuestSession.new(player_identifier).send()
	
	login_btn.disabled = false # 恢復按鈕
	
	if response.success:
		status_label.text = "✅ 連線成功！正在同步雲端進度..."
		status_label.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		
		# 【新增】呼叫 SaveManager 從 LootLocker 下載這名玩家的專屬進度
		await SaveManager.load_from_cloud()
		
		# 下載完成後，轉跳到主遊戲畫面
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		# 顯示伺服器回傳的錯誤
		status_label.text = "❌ 連線失敗，請檢查網路狀態"
		status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
