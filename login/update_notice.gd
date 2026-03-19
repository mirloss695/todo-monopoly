class_name UpdateNotice
## 版本更新提示視窗
## 使用方式：await UpdateNotice.new().try_show(host_control)
## 若玩家已看過此版本的公告則自動跳過

## ── 在這裡編輯版本號與更新內容 ──
const CURRENT_VERSION = "0.1.1"
const CHANGELOG = [
	"新增「明日任務預先規劃」功能",
] ## 已發布

## 檢查是否需要顯示，需要則彈窗並等待玩家關閉
func try_show(host: Control) -> void:
	var last_seen = SaveManager.last_seen_version
	if last_seen == CURRENT_VERSION:
		return  # 已看過，跳過

	# 記錄已讀
	SaveManager.last_seen_version = CURRENT_VERSION

	await _show_popup(host)

	# 存檔讓下次不再顯示
	SaveManager.save_to_cloud()

## ── 建構並顯示彈窗 ──
func _show_popup(host: Control) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	host.add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.z_index = 201
	host.add_child(center)

	var panel = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color("#2C2C2C")
	ps.corner_radius_top_left = 20
	ps.corner_radius_top_right = 20
	ps.corner_radius_bottom_left = 20
	ps.corner_radius_bottom_right = 20
	ps.shadow_color = Color(0, 0, 0, 0.5)
	ps.shadow_size = 12
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var pm = MarginContainer.new()
	pm.add_theme_constant_override("margin_top", 40)
	pm.add_theme_constant_override("margin_bottom", 40)
	pm.add_theme_constant_override("margin_left", 50)
	pm.add_theme_constant_override("margin_right", 50)
	panel.add_child(pm)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 20)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	pm.add_child(vb)

	# 標題
	var title = Label.new()
	title.text = "版本更新 v%s" % CURRENT_VERSION
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.set("theme_override_colors/font_color", Color.GOLD)
	vb.add_child(title)

	# 更新內容
	for line in CHANGELOG:
		var lbl = Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 19)
		lbl.set("theme_override_colors/font_color", Color.WHITE)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(420, 0)
		vb.add_child(lbl)

	# 確認按鈕
	var ok_btn = Button.new()
	ok_btn.text = "朕知道了"
	ok_btn.custom_minimum_size = Vector2(180, 50)
	ok_btn.add_theme_font_size_override("font_size", 22)
	ok_btn.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	ok_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	vb.add_child(ok_btn)

	# 等待點擊
	var done = [false]
	ok_btn.pressed.connect(func(): done[0] = true)
	while not done[0]:
		await host.get_tree().process_frame

	overlay.queue_free()
	center.queue_free()
