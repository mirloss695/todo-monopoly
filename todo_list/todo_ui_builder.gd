class_name TodoUIBuilder
## 負責建構 TodoList 所有靜態 UI 元件（標題列、分數列、欄位標題、按鈕列等）

static func build(host: Control) -> Dictionary:
	var refs := {}

	var bg = ColorRect.new()
	bg.color = Color("#2C2C2C")
	host.add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var margin = MarginContainer.new()
	host.add_child(margin)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_bottom", 40)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	main_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # ← 新增
	margin.add_child(main_vbox)

	# --- 第一列：日期導覽 ---
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 15)

	var prev_day_btn = _make_nav_button("◀")
	header_hbox.add_child(prev_day_btn)
	refs["prev_day_btn"] = prev_day_btn

	var header_label = Label.new()
	header_label.add_theme_font_size_override("font_size", 26)
	header_label.set("theme_override_colors/font_color", Color.GOLD)
	header_hbox.add_child(header_label)
	refs["header_label"] = header_label

	var next_day_btn = _make_nav_button("▶")
	header_hbox.add_child(next_day_btn)
	refs["next_day_btn"] = next_day_btn

	var today_btn = Button.new()
	today_btn.text = "📌 今天"
	today_btn.custom_minimum_size = Vector2(90, 40)
	today_btn.add_theme_font_size_override("font_size", 18)
	today_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	today_btn.hide()
	header_hbox.add_child(today_btn)
	refs["today_btn"] = today_btn

	main_vbox.add_child(header_hbox)

	# --- 第二列：點數與加權上限 ---
	var limits_label = Label.new()
	limits_label.add_theme_font_size_override("font_size", 22)
	limits_label.set("theme_override_colors/font_color", Color.LIGHT_GOLDENROD)
	main_vbox.add_child(limits_label)
	refs["limits_label"] = limits_label

	# --- 第三列：累計分數 ---
	var score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 22)
	main_vbox.add_child(score_label)
	refs["score_label"] = score_label

	var board_status_label = Label.new()
	board_status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
	board_status_label.add_theme_font_size_override("font_size", 18)
	main_vbox.add_child(board_status_label)
	refs["board_status_label"] = board_status_label

	# --- 欄位標題列 ---
	main_vbox.add_child(_build_column_titles())

	# --- 捲動區域 ---
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 200)

	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_vbox)

	var tasks_container = VBoxContainer.new()
	tasks_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_child(tasks_container)
	refs["tasks_container"] = tasks_container

	var history_container = VBoxContainer.new()
	history_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_container.hide()
	scroll_vbox.add_child(history_container)
	refs["scroll_vbox"] = scroll_vbox
	refs["history_container"] = history_container
	
	var next_day_container = VBoxContainer.new()
	next_day_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_day_container.hide()
	scroll_vbox.add_child(next_day_container)
	refs["next_day_container"] = next_day_container
	
	main_vbox.add_child(scroll)

	# --- 按鈕列 ---
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)

	var add_task_btn = Button.new()
	add_task_btn.text = "➕ 新增任務"
	add_task_btn.custom_minimum_size = Vector2(180, 60)
	add_task_btn.add_theme_font_size_override("font_size", 22)
	btn_hbox.add_child(add_task_btn)
	refs["add_task_btn"] = add_task_btn

	var toggle_save_btn = Button.new()
	toggle_save_btn.text = "💾 確認儲存"
	toggle_save_btn.custom_minimum_size = Vector2(250, 60)
	toggle_save_btn.add_theme_font_size_override("font_size", 22)
	toggle_save_btn.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	btn_hbox.add_child(toggle_save_btn)
	refs["toggle_save_btn"] = toggle_save_btn

	var finish_btn = Button.new()
	finish_btn.text = "🚩 結算今日得分"
	finish_btn.custom_minimum_size = Vector2(200, 60)
	finish_btn.add_theme_font_size_override("font_size", 22)
	finish_btn.disabled = true
	btn_hbox.add_child(finish_btn)
	refs["finish_btn"] = finish_btn

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(spacer)
	main_vbox.add_child(btn_hbox)
	refs["btn_hbox"] = btn_hbox

	# --- 警告對話框 ---
	var warning_dialog = AcceptDialog.new()
	warning_dialog.title = "⚠️ 規則警告"
	host.add_child(warning_dialog)
	var dialog_label = warning_dialog.get_label()
	dialog_label.add_theme_font_size_override("font_size", 18)
	dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ok_btn = warning_dialog.get_ok_button()
	ok_btn.add_theme_font_size_override("font_size", 18)
	ok_btn.custom_minimum_size = Vector2(100, 40)
	refs["warning_dialog"] = warning_dialog
	
	# --- 結算確認對話框 ---
	var confirm_finish_dialog = ConfirmationDialog.new()
	confirm_finish_dialog.title = "🚩 確認結算今日得分"
	confirm_finish_dialog.dialog_text = "結算後將會前往地圖擲骰子，\n任務清單將鎖定，無法再編輯。\n\n確定要結算今日得分嗎？"
	host.add_child(confirm_finish_dialog)
	var cfd_label = confirm_finish_dialog.get_label()
	cfd_label.add_theme_font_size_override("font_size", 18)
	cfd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_finish_dialog.get_ok_button().text = "✅ 確認結算"
	confirm_finish_dialog.get_ok_button().add_theme_font_size_override("font_size", 18)
	confirm_finish_dialog.get_ok_button().custom_minimum_size = Vector2(120, 40)
	confirm_finish_dialog.get_cancel_button().text = "再想想"
	confirm_finish_dialog.get_cancel_button().add_theme_font_size_override("font_size", 18)
	confirm_finish_dialog.get_cancel_button().custom_minimum_size = Vector2(100, 40)
	refs["confirm_finish_dialog"] = confirm_finish_dialog

	return refs

# ── 內部工具 ──

static func _make_nav_button(label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(40, 40)
	btn.add_theme_font_size_override("font_size", 20)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn

static func _build_column_titles() -> HBoxContainer:
	var title_hbox = HBoxContainer.new()
	var titles = ["編號", "", "任務內容", "分配點數", "加權(1-5)", "任務得分", ""]
	var widths = [50, 60, 400, 120, 120, 120, 100]
	for i in range(titles.size()):
		var l = Label.new()
		l.text = titles[i]
		l.custom_minimum_size = Vector2(widths[i], 0)
		if i == 2: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		else: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.set("theme_override_colors/font_color", Color.LIGHT_SKY_BLUE)
		l.add_theme_font_size_override("font_size", 20)
		title_hbox.add_child(l)
	return title_hbox
