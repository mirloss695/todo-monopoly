extends Control

var current_stage = 1
var total_accumulated_score = 0 
var today_total_score = 0       
var daily_points_limit = 100 
var weight_limit = 30           

var is_editing = true         
var can_switch_board = false  
var task_rows = []   

# --- 時光機歷史系統變數 ---
var actual_day = 1        # 實際進行到的天數
var current_view_day = 1  # 玩家目前畫面上正在看的天數
var task_history = {}     # 儲存過去資料的字典 { 天數: { tasks: [...], score: 100 } }

var bg: ColorRect
var margin: MarginContainer
var header_hbox: HBoxContainer
var prev_day_btn: Button
var next_day_btn: Button
var header_label: Label
var score_label: Label

var scroll_vbox: VBoxContainer
var tasks_container: VBoxContainer         # 今日任務容器 (可編輯)
var history_container: VBoxContainer       # 歷史任務容器 (唯讀)

var btn_hbox: HBoxContainer                # 底部按鈕區
var add_task_btn: Button
var toggle_save_btn: Button   
var finish_btn: Button
var warning_dialog: AcceptDialog
var board_status_label: Label 

func _ready():
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	daily_points_limit = current_stage * 100
	setup_ui()
	update_day_navigation() # 初始化時光機導航
	add_task_row()

func setup_ui():
	bg = ColorRect.new()
	bg.color = Color("#2C2C2C")
	add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	margin = MarginContainer.new()
	add_child(margin)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	margin.add_theme_constant_override("margin_top", 30)    
	margin.add_theme_constant_override("margin_left", 80)   
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_bottom", 40)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)
	
	# 【新增】將標題改為水平容器，並加入左右切換按鈕
	header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 15)
	
	prev_day_btn = Button.new()
	prev_day_btn.text = "◀"
	prev_day_btn.custom_minimum_size = Vector2(40, 40)
	prev_day_btn.add_theme_font_size_override("font_size", 20)
	prev_day_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	prev_day_btn.pressed.connect(_on_prev_day_pressed)
	header_hbox.add_child(prev_day_btn)
	
	header_label = Label.new()
	header_label.add_theme_font_size_override("font_size", 26) 
	header_label.set("theme_override_colors/font_color", Color.GOLD)
	header_hbox.add_child(header_label)
	
	next_day_btn = Button.new()
	next_day_btn.text = "▶"
	next_day_btn.custom_minimum_size = Vector2(40, 40)
	next_day_btn.add_theme_font_size_override("font_size", 20)
	next_day_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_day_btn.pressed.connect(_on_next_day_pressed)
	header_hbox.add_child(next_day_btn)
	
	main_vbox.add_child(header_hbox)
	
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 22) 
	main_vbox.add_child(score_label)
	
	board_status_label = Label.new()
	board_status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
	board_status_label.add_theme_font_size_override("font_size", 18)
	main_vbox.add_child(board_status_label)
	
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
	main_vbox.add_child(title_hbox)
	
	# 【修改】加入卷軸容器，並在裡面放兩個 VBox (今日/歷史)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL 
	scroll.custom_minimum_size = Vector2(0, 250) 
	scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll_vbox.size_flags_vertical = SIZE_EXPAND_FILL 
	scroll.add_child(scroll_vbox)
	
	tasks_container = VBoxContainer.new() # 今日容器
	tasks_container.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll_vbox.add_child(tasks_container)
	
	history_container = VBoxContainer.new() # 歷史容器 (預設隱藏)
	history_container.size_flags_horizontal = SIZE_EXPAND_FILL
	history_container.hide()
	scroll_vbox.add_child(history_container)
	
	main_vbox.add_child(scroll)
	
	# 底部按鈕區
	btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)
	
	add_task_btn = Button.new()
	add_task_btn.text = "➕ 新增任務"
	add_task_btn.custom_minimum_size = Vector2(180, 60)
	add_task_btn.add_theme_font_size_override("font_size", 22)
	add_task_btn.pressed.connect(_on_add_task_pressed)
	btn_hbox.add_child(add_task_btn)
	
	toggle_save_btn = Button.new()
	toggle_save_btn.text = "💾 確認儲存"
	toggle_save_btn.custom_minimum_size = Vector2(250, 60)
	toggle_save_btn.add_theme_font_size_override("font_size", 22)
	toggle_save_btn.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	toggle_save_btn.pressed.connect(_on_toggle_save_pressed)
	btn_hbox.add_child(toggle_save_btn)
	
	finish_btn = Button.new()
	finish_btn.text = "🚩 結算今日得分"
	finish_btn.custom_minimum_size = Vector2(200, 60)
	finish_btn.add_theme_font_size_override("font_size", 22)
	finish_btn.disabled = true 
	finish_btn.pressed.connect(_on_finish_pressed)
	btn_hbox.add_child(finish_btn)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10) 
	main_vbox.add_child(spacer)
	main_vbox.add_child(btn_hbox)
	
	warning_dialog = AcceptDialog.new()
	warning_dialog.title = "⚠️ 規則警告"
	add_child(warning_dialog)
	var dialog_label = warning_dialog.get_label()
	dialog_label.add_theme_font_size_override("font_size", 18)
	dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ok_btn = warning_dialog.get_ok_button()
	ok_btn.add_theme_font_size_override("font_size", 18)
	ok_btn.custom_minimum_size = Vector2(100, 40)

# ==========================================
# 時光機與歷史紀錄系統 (新增區塊)
# ==========================================
func update_day_navigation():
	header_label.text = "📝 第 %d 天任務規劃 (階段 %d) | 今日可用點數: %d | 加權總和上限: %d" % [current_view_day, current_stage, daily_points_limit, weight_limit]
	
	prev_day_btn.disabled = (current_view_day <= 1)
	next_day_btn.disabled = (current_view_day >= actual_day)
	
	if current_view_day == actual_day:
		# 觀看「今天」：顯示編輯介面
		history_container.hide()
		tasks_container.show()
		btn_hbox.show()
		board_status_label.show()
		update_score_display()
	else:
		# 觀看「歷史」：顯示唯讀介面
		tasks_container.hide()
		btn_hbox.hide()
		board_status_label.hide()
		build_history_view(current_view_day)
		history_container.show()
		var hist_score = task_history[current_view_day]["score"] if task_history.has(current_view_day) else 0
		score_label.text = "🏆 歷史總分檢視  |  🌟 第 %d 天獲得分數: %d" % [current_view_day, hist_score]

func _on_prev_day_pressed():
	if current_view_day > 1:
		current_view_day -= 1
		update_day_navigation()

func _on_next_day_pressed():
	if current_view_day < actual_day:
		current_view_day += 1
		update_day_navigation()

func build_history_view(day: int):
	# 清空舊的歷史視圖
	for child in history_container.get_children():
		child.queue_free()
		
	var data = task_history.get(day, {"tasks": [], "score": 0})
	var index = 1
	var widths = [50, 60, 400, 120, 120, 120, 100] 
	
	for task in data["tasks"]:
		var row = HBoxContainer.new()
		
		# 1. 編號
		var num_lbl = Label.new()
		num_lbl.custom_minimum_size = Vector2(widths[0], 0)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_size_override("font_size", 20)
		num_lbl.text = str(index) + "."
		row.add_child(num_lbl)
		
		# 2. 打勾狀態 (唯讀)
		var check_lbl = Label.new()
		check_lbl.custom_minimum_size = Vector2(widths[1], 0)
		check_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		check_lbl.add_theme_font_size_override("font_size", 24)
		check_lbl.text = "✔" if task["completed"] else ""
		check_lbl.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		row.add_child(check_lbl)
		
		# 3. 任務內容 (唯讀)
		var line_edit = LineEdit.new()
		line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
		line_edit.custom_minimum_size = Vector2(widths[2], 0)
		line_edit.add_theme_font_size_override("font_size", 20)
		line_edit.text = task["text"]
		line_edit.editable = false
		line_edit.add_theme_color_override("font_uneditable_color", Color.WHITE)
		row.add_child(line_edit)
		
		# 4. 分配點數 (唯讀)
		var pts_edit = LineEdit.new()
		pts_edit.custom_minimum_size = Vector2(widths[3], 0)
		pts_edit.text = str(task["points"])
		pts_edit.editable = false
		pts_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER # 【修正這裡】
		row.add_child(pts_edit)
		
		# 5. 加權 (唯讀)
		var wt_edit = LineEdit.new()
		wt_edit.custom_minimum_size = Vector2(widths[4], 0)
		wt_edit.text = str(task["weight"])
		wt_edit.editable = false
		wt_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER # 【修正這裡】
		row.add_child(wt_edit)
		
		# 6. 任務得分 (唯讀)
		var sc_lbl = Label.new()
		sc_lbl.custom_minimum_size = Vector2(widths[5], 0)
		sc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sc_lbl.add_theme_font_size_override("font_size", 20)
		var t_score = task["points"] * task["weight"]
		sc_lbl.text = "+ " + str(t_score) if task["completed"] else "-"
		sc_lbl.set("theme_override_colors/font_color", Color.GREEN_YELLOW if task["completed"] else Color.WHITE)
		row.add_child(sc_lbl)
		
		# 7. 佔位符 (取代刪除按鈕，維持排版對齊)
		var dummy = Control.new()
		dummy.custom_minimum_size = Vector2(widths[6], 0)
		row.add_child(dummy)
		
		history_container.add_child(row)
		index += 1
# ==========================================
# 既有功能區
# ==========================================
func update_task_numbers():
	for i in range(task_rows.size()):
		task_rows[i]["num_lbl"].text = str(i + 1) + "."

func add_task_row():
	if not is_editing: return 
	
	var row = HBoxContainer.new()
	var row_data = {} 
	
	var num_lbl = Label.new()
	num_lbl.custom_minimum_size = Vector2(50, 0)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 20)
	row.add_child(num_lbl)
	
	var cb_container = CenterContainer.new()
	cb_container.custom_minimum_size = Vector2(60, 0) 
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
	
	var line_edit = LineEdit.new()
	line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	line_edit.custom_minimum_size = Vector2(300, 0)
	line_edit.placeholder_text = "請輸入任務內容..."
	line_edit.add_theme_font_size_override("font_size", 20) 
	row.add_child(line_edit)
	
	var points_spin = SpinBox.new()
	points_spin.custom_minimum_size = Vector2(120, 0)
	points_spin.max_value = daily_points_limit 
	row.add_child(points_spin)
	
	var weight_spin = SpinBox.new()
	weight_spin.custom_minimum_size = Vector2(120, 0)
	weight_spin.min_value = 1
	weight_spin.max_value = 5
	weight_spin.value = 1
	row.add_child(weight_spin)
	
	var task_score_lbl = Label.new()
	task_score_lbl.custom_minimum_size = Vector2(120, 0)
	task_score_lbl.text = "-"
	task_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	task_score_lbl.add_theme_font_size_override("font_size", 20)
	row.add_child(task_score_lbl)
	
	var del_btn = Button.new()
	del_btn.text = "🗑️ 刪除"
	del_btn.custom_minimum_size = Vector2(100, 0)
	row.add_child(del_btn)
	
	row_data["row_node"] = row
	row_data["num_lbl"] = num_lbl 
	row_data["checkbox"] = checkbox
	row_data["check_mark"] = check_mark
	row_data["line_edit"] = line_edit
	row_data["points_spin"] = points_spin
	row_data["weight_spin"] = weight_spin
	row_data["del_btn"] = del_btn
	row_data["is_completed"] = false 
	
	del_btn.pressed.connect(_on_delete_task.bind(row_data))
	checkbox.toggled.connect(_on_task_toggled.bind(row_data, task_score_lbl))
	
	tasks_container.add_child(row)
	task_rows.append(row_data)
	update_task_numbers() 

func _on_delete_task(row_data: Dictionary):
	if row_data["is_completed"]:
		warning_dialog.dialog_text = "該任務已打勾完成，無法刪除！\n如需刪除請先取消勾選。"
		warning_dialog.popup_centered()
		return
	row_data["row_node"].queue_free() 
	task_rows.erase(row_data)
	update_task_numbers() 

func update_score_display():
	if current_view_day == actual_day:
		score_label.text = "🏆 目前累計分數: %d  |  🌟 本日總分: %d" % [total_accumulated_score, today_total_score]

func _on_add_task_pressed(): add_task_row()

func _on_toggle_save_pressed():
	if is_editing:
		var total_points = 0
		var total_weights = 0
		
		for row_data in task_rows:
			if row_data["line_edit"].text.strip_edges() == "":
				warning_dialog.dialog_text = "有任務尚未填寫內容哦！\n請填寫或點擊刪除空白任務。"
				warning_dialog.popup_centered()
				return
			total_points += row_data["points_spin"].value
			total_weights += row_data["weight_spin"].value
		
		if total_points > daily_points_limit:
			warning_dialog.dialog_text = "儲存失敗！\n分配點數總和 (%d) 超過上限 (%d)。" % [total_points, daily_points_limit]
			warning_dialog.popup_centered()
			return
		if total_weights > weight_limit:
			warning_dialog.dialog_text = "儲存失敗！\n加權總和 (%d) 超過上限 (%d)。" % [total_weights, weight_limit]
			warning_dialog.popup_centered()
			return
			
		is_editing = false
		can_switch_board = true
		add_task_btn.disabled = true
		toggle_save_btn.text = "✏️ 修改任務 (解鎖)"
		toggle_save_btn.set("theme_override_colors/font_color", Color.WHITE)
		finish_btn.disabled = false 
		
		board_status_label.text = "✅ 已儲存。目前可以隨時切換到其他板塊囉！"
		board_status_label.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		
		for row_data in task_rows:
			row_data["line_edit"].editable = false
			row_data["points_spin"].editable = false
			row_data["weight_spin"].editable = false
			row_data["del_btn"].disabled = true
			row_data["checkbox"].disabled = false 
	else:
		is_editing = true
		can_switch_board = false
		add_task_btn.disabled = false
		toggle_save_btn.text = "💾 確認儲存"
		toggle_save_btn.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		finish_btn.disabled = true 
		
		board_status_label.text = "⚠️ 任務修改中，儲存前無法轉跳板塊！"
		board_status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
		
		for row_data in task_rows:
			row_data["checkbox"].disabled = true 
			if not row_data["is_completed"]:
				row_data["line_edit"].editable = true
				row_data["points_spin"].editable = true
				row_data["weight_spin"].editable = true
				row_data["del_btn"].disabled = false

func _on_task_toggled(is_checked: bool, row_data: Dictionary, task_score_lbl: Label):
	var task_score = row_data["points_spin"].value * row_data["weight_spin"].value
	if is_checked:
		print("🎵 [播放音效: 叮！]") 
		row_data["is_completed"] = true
		row_data["check_mark"].text = "✔"
		task_score_lbl.text = "+ " + str(task_score)
		task_score_lbl.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
		today_total_score += task_score
	else:
		row_data["is_completed"] = false
		row_data["check_mark"].text = ""
		task_score_lbl.text = "-"
		task_score_lbl.set("theme_override_colors/font_color", Color.WHITE)
		today_total_score -= task_score
	update_score_display()
	
func _on_finish_pressed():
	total_accumulated_score += today_total_score
	update_score_display()
	finish_btn.disabled = true
	finish_btn.text = "已結算"
	toggle_save_btn.disabled = true 
	for row_data in task_rows:
		row_data["checkbox"].disabled = true

func reset_for_new_day():
	# 【關鍵修復】在清空畫面之前，先把今天的資料「存檔」進歷史資料庫！
	var history_data = []
	for row_data in task_rows:
		history_data.append({
			"text": row_data["line_edit"].text,
			"points": row_data["points_spin"].value,
			"weight": row_data["weight_spin"].value,
			"completed": row_data["is_completed"]
		})
	task_history[actual_day] = {
		"tasks": history_data,
		"score": today_total_score
	}
	
	# 天數推進
	actual_day += 1
	current_view_day = actual_day
	update_day_navigation()
	
	# 重置今日狀態
	today_total_score = 0
	is_editing = true
	can_switch_board = false
	add_task_btn.disabled = false
	toggle_save_btn.text = "💾 確認儲存"
	toggle_save_btn.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	toggle_save_btn.disabled = false
	finish_btn.disabled = true
	finish_btn.text = "🚩 結算今日得分"
	board_status_label.text = "⚠️ 目前有未儲存的變更，無法轉跳板塊！"
	board_status_label.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
	
	for row_data in task_rows:
		row_data["row_node"].queue_free()
	task_rows.clear()
	add_task_row()
	update_score_display()
