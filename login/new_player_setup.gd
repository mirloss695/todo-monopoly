class_name NewPlayerSetup
## 新玩家初始設定視窗（玩家名稱 + 獎勵目標）

signal setup_done

var _overlay: ColorRect
var _center: CenterContainer

## 在指定 host 上顯示設定視窗，完成後自動清除
## 使用方式: await NewPlayerSetup.new().show_on(host)
func show_on(host: Control) -> void:
	# --- 遮罩背景 ---
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.80)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.z_index = 200
	host.add_child(_overlay)

	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center.z_index = 201
	host.add_child(_center)

	# --- 面板 ---
	var setup_panel = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color("#2C2C2C")
	ps.corner_radius_top_left = 20
	ps.corner_radius_top_right = 20
	ps.corner_radius_bottom_left = 20
	ps.corner_radius_bottom_right = 20
	setup_panel.add_theme_stylebox_override("panel", ps)
	_center.add_child(setup_panel)

	var pm = MarginContainer.new()
	pm.add_theme_constant_override("margin_top", 50)
	pm.add_theme_constant_override("margin_bottom", 50)
	pm.add_theme_constant_override("margin_left", 60)
	pm.add_theme_constant_override("margin_right", 60)
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
		SaveManager.save_to_cloud()
		_cleanup()
		setup_done.emit()
	)

	await self.setup_done

func _cleanup():
	if is_instance_valid(_overlay): _overlay.queue_free()
	if is_instance_valid(_center): _center.queue_free()
