class_name TodoHistory
## 負責時光機歷史紀錄的 UI 建構

const COL_WIDTHS = [50, 60, 400, 120, 120, 120, 100]

## 清空 history_container 並根據指定天數的歷史資料重建唯讀列表
static func build_view(container: VBoxContainer, day: int, task_history: Dictionary) -> void:
	for child in container.get_children():
		child.queue_free()
	
	# 等一幀讓舊節點清除
	await container.get_tree().process_frame
	
	var data = task_history.get(day, {"tasks": [], "score": 0})
	var index = 1

	for task in data["tasks"]:
		var row = _build_history_row(index, task)
		container.add_child(row)
		index += 1

## 計算指定天數的歷史得分
static func get_day_score(day: int, task_history: Dictionary) -> int:
	if task_history.has(day):
		return task_history[day]["score"]
	return 0

# ── 內部：建構單一歷史列 ──

static func _build_history_row(index: int, task: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()

	# 編號
	var num_lbl = Label.new()
	num_lbl.custom_minimum_size = Vector2(COL_WIDTHS[0], 0)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 20)
	num_lbl.text = str(index) + "."
	row.add_child(num_lbl)

	# 勾選標記
	var check_lbl = Label.new()
	check_lbl.custom_minimum_size = Vector2(COL_WIDTHS[1], 0)
	check_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check_lbl.add_theme_font_size_override("font_size", 24)
	check_lbl.text = "✔" if task["completed"] else ""
	check_lbl.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	row.add_child(check_lbl)

	# 任務內容（唯讀）
	var line_edit = LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.custom_minimum_size = Vector2(COL_WIDTHS[2], 0)
	line_edit.add_theme_font_size_override("font_size", 20)
	line_edit.text = task["text"]
	line_edit.editable = false
	line_edit.add_theme_color_override("font_uneditable_color", Color.WHITE)
	row.add_child(line_edit)

	# 分配點數（唯讀）
	var pts_edit = LineEdit.new()
	pts_edit.custom_minimum_size = Vector2(COL_WIDTHS[3], 0)
	pts_edit.text = str(task["points"])
	pts_edit.editable = false
	pts_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(pts_edit)

	# 加權（唯讀）
	var wt_edit = LineEdit.new()
	wt_edit.custom_minimum_size = Vector2(COL_WIDTHS[4], 0)
	wt_edit.text = str(task["weight"])
	wt_edit.editable = false
	wt_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(wt_edit)

	# 任務得分
	var sc_lbl = Label.new()
	sc_lbl.custom_minimum_size = Vector2(COL_WIDTHS[5], 0)
	sc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc_lbl.add_theme_font_size_override("font_size", 20)
	var t_score = task["points"] * task["weight"]
	sc_lbl.text = "+ " + str(t_score) if task["completed"] else "-"
	sc_lbl.set("theme_override_colors/font_color", Color.GREEN_YELLOW if task["completed"] else Color.WHITE)
	row.add_child(sc_lbl)

	# 佔位
	var dummy = Control.new()
	dummy.custom_minimum_size = Vector2(COL_WIDTHS[6], 0)
	row.add_child(dummy)

	return row
