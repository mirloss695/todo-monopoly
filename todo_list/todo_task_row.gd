class_name TodoTaskRow
## 負責單一任務列的建立、刪除、勾選邏輯

const COL_WIDTHS = [50, 60, 400, 120, 120, 120, 100]

## 建立一列新的可編輯任務，回傳 row_data Dictionary
static func create(container: VBoxContainer, daily_points_limit: int) -> Dictionary:
	var row = HBoxContainer.new()
	var row_data := {}

	# 編號
	var num_lbl = Label.new()
	num_lbl.custom_minimum_size = Vector2(COL_WIDTHS[0], 0)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 20)
	row.add_child(num_lbl)

	# 勾選按鈕
	var cb_container = CenterContainer.new()
	cb_container.custom_minimum_size = Vector2(COL_WIDTHS[1], 0)
	var checkbox = Button.new()
	checkbox.toggle_mode = true
	checkbox.text = ""
	checkbox.custom_minimum_size = Vector2(36, 36)
	checkbox.disabled = true
	cb_container.add_child(checkbox)

	var check_mark = Label.new()
	check_mark.text = ""
	check_mark.add_theme_font_size_override("font_size", 24)
	check_mark.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	check_mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	check_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	check_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	checkbox.add_child(check_mark)
	row.add_child(cb_container)

	# 任務內容
	var line_edit = LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.custom_minimum_size = Vector2(300, 0)
	line_edit.placeholder_text = "請輸入任務內容..."
	line_edit.add_theme_font_size_override("font_size", 20)
	row.add_child(line_edit)

	# 分配點數
	var points_spin = SpinBox.new()
	points_spin.custom_minimum_size = Vector2(COL_WIDTHS[3], 0)
	points_spin.max_value = daily_points_limit
	row.add_child(points_spin)

	# 加權
	var weight_spin = SpinBox.new()
	weight_spin.custom_minimum_size = Vector2(COL_WIDTHS[4], 0)
	weight_spin.min_value = 1
	weight_spin.max_value = 5
	weight_spin.value = 1
	row.add_child(weight_spin)

	# 任務得分
	var task_score_lbl = Label.new()
	task_score_lbl.custom_minimum_size = Vector2(COL_WIDTHS[5], 0)
	task_score_lbl.text = "-"
	task_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	task_score_lbl.add_theme_font_size_override("font_size", 20)
	row.add_child(task_score_lbl)

	# 刪除按鈕
	var del_btn = Button.new()
	del_btn.text = "🗑️ 刪除"
	del_btn.custom_minimum_size = Vector2(COL_WIDTHS[6], 0)
	row.add_child(del_btn)

	row_data["row_node"] = row
	row_data["num_lbl"] = num_lbl
	row_data["checkbox"] = checkbox
	row_data["check_mark"] = check_mark
	row_data["line_edit"] = line_edit
	row_data["points_spin"] = points_spin
	row_data["weight_spin"] = weight_spin
	row_data["task_score_lbl"] = task_score_lbl
	row_data["del_btn"] = del_btn
	row_data["is_completed"] = false

	container.add_child(row)
	return row_data

## 設定該列為鎖定（儲存後）或解鎖（編輯中）
static func set_locked(row_data: Dictionary, locked: bool) -> void:
	if locked:
		row_data["line_edit"].editable = false
		row_data["line_edit"].add_theme_color_override("font_uneditable_color", Color.WHITE)
		row_data["points_spin"].editable = false
		row_data["points_spin"].get_line_edit().add_theme_color_override("font_uneditable_color", Color.WHITE)
		row_data["weight_spin"].editable = false
		row_data["weight_spin"].get_line_edit().add_theme_color_override("font_uneditable_color", Color.WHITE)
		row_data["del_btn"].disabled = true
		row_data["checkbox"].disabled = false
	else:
		row_data["checkbox"].disabled = true
		if not row_data["is_completed"]:
			row_data["line_edit"].editable = true
			row_data["points_spin"].editable = true
			row_data["weight_spin"].editable = true
			row_data["del_btn"].disabled = false

## 處理勾選/取消勾選，回傳分數變化量（正或負）
static func handle_toggle(is_checked: bool, row_data: Dictionary) -> int:
	var task_score = int(row_data["points_spin"].value * row_data["weight_spin"].value)
	var score_lbl: Label = row_data["task_score_lbl"]

	if is_checked:
		row_data["is_completed"] = true
		row_data["check_mark"].text = "✔"
		score_lbl.text = "+ " + str(task_score)
		score_lbl.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		return task_score
	else:
		row_data["is_completed"] = false
		row_data["check_mark"].text = ""
		score_lbl.text = "-"
		score_lbl.set("theme_override_colors/font_color", Color.WHITE)
		return -task_score

## 將 row_data 序列化為可儲存的 Dictionary
static func serialize(row_data: Dictionary) -> Dictionary:
	return {
		"text": row_data["line_edit"].text,
		"points": row_data["points_spin"].value,
		"weight": row_data["weight_spin"].value,
		"completed": row_data["is_completed"]
	}
