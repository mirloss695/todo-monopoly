extends Control
## TodoList 主控制器
## UI 建構委託給 TodoUIBuilder
## 任務列操作委託給 TodoTaskRow
## 歷史檢視委託給 TodoHistory

signal request_save  # ← main.gd 監聽此訊號並呼叫 _save_to_save_manager()

var current_stage = 1
var total_accumulated_score = 0
var today_total_score = 0
var daily_points_limit = 100
var weight_limit = 30

var is_editing = true
var can_switch_board = false
var task_rows = []

var scroll_vbox: VBoxContainer

# --- 時光機歷史系統變數 ---
var actual_day = 1
var current_view_day = 1
var task_history = {}

# --- UI 參照（由 TodoUIBuilder 建立） ---
var header_label: Label
var limits_label: Label
var score_label: Label
var board_status_label: Label
var tasks_container: VBoxContainer
var history_container: VBoxContainer
var btn_hbox: HBoxContainer
var add_task_btn: Button
var toggle_save_btn: Button
var finish_btn: Button
var prev_day_btn: Button
var next_day_btn: Button
var today_btn: Button
var warning_dialog: AcceptDialog
var sfx_complete: AudioStreamPlayer

func _ready():
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	daily_points_limit = current_stage * 100
	_setup_ui()
	update_day_navigation()
	add_task_row()

func _setup_ui():
	var refs = TodoUIBuilder.build(self)
	today_btn = refs["today_btn"]
	today_btn.pressed.connect(func():
		current_view_day = actual_day
		update_day_navigation()
	)
	scroll_vbox = refs["scroll_vbox"]
	header_label       = refs["header_label"]
	limits_label       = refs["limits_label"]
	score_label        = refs["score_label"]
	board_status_label = refs["board_status_label"]
	tasks_container    = refs["tasks_container"]
	history_container  = refs["history_container"]
	btn_hbox           = refs["btn_hbox"]
	add_task_btn       = refs["add_task_btn"]
	toggle_save_btn    = refs["toggle_save_btn"]
	finish_btn         = refs["finish_btn"]
	warning_dialog     = refs["warning_dialog"]
	prev_day_btn       = refs["prev_day_btn"]
	next_day_btn       = refs["next_day_btn"]

	prev_day_btn.pressed.connect(_on_prev_day_pressed)
	next_day_btn.pressed.connect(_on_next_day_pressed)
	add_task_btn.pressed.connect(_on_add_task_pressed)
	toggle_save_btn.pressed.connect(_on_toggle_save_pressed)
	finish_btn.pressed.connect(_on_finish_pressed)
	
	sfx_complete = AudioStreamPlayer.new()
	var stream = load("res://sounds/task_complete.wav")
	if stream:
		sfx_complete.stream = stream
	add_child(sfx_complete)

# ==========================================
# 時光機與歷史紀錄系統
# ==========================================
func update_day_navigation():
	header_label.text = "📝 第 %d 天任務規劃 (階段 %d)" % [current_view_day, current_stage]
	limits_label.text = "🎯 今日可用點數: %d  |  ⚖️ 加權總和上限: %d" % [daily_points_limit, weight_limit]

	prev_day_btn.disabled = (current_view_day <= 1)
	next_day_btn.disabled = (current_view_day >= actual_day)

	if current_view_day == actual_day:
		today_btn.hide()
		history_container.hide()
		tasks_container.show()
		btn_hbox.show()
		board_status_label.show()
		limits_label.show()
		update_score_display()
	else:
		limits_label.hide()
		today_btn.show()
		print("📜 [TodoList] 切換至歷史 day=%d, task_history keys=%s" % [current_view_day, str(task_history.keys())])
		tasks_container.hide()
		btn_hbox.hide()
		board_status_label.hide()

		history_container.show()
		await TodoHistory.build_view(history_container, current_view_day, task_history)
		var hist_score = TodoHistory.get_day_score(current_view_day, task_history)
		score_label.text = "🌟 第 %d 天獲得分數: %d" % [current_view_day, hist_score]

func _on_prev_day_pressed():
	if current_view_day > 1:
		current_view_day -= 1
		update_day_navigation()

func _on_next_day_pressed():
	if current_view_day < actual_day:
		current_view_day += 1
		update_day_navigation()

# ==========================================
# 任務列操作
# ==========================================
func update_task_numbers():
	for i in range(task_rows.size()):
		task_rows[i]["num_lbl"].text = str(i + 1) + "."

func add_task_row():
	if not is_editing: return
	var row_data = TodoTaskRow.create(tasks_container, daily_points_limit)
	row_data["del_btn"].pressed.connect(_on_delete_task.bind(row_data))
	row_data["checkbox"].toggled.connect(_on_task_toggled.bind(row_data))
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

# ==========================================
# 💾 存檔節點：勾選 / 取消勾選核取方塊
# ==========================================
func _on_task_toggled(is_checked: bool, row_data: Dictionary):
	var delta = TodoTaskRow.handle_toggle(is_checked, row_data)
	today_total_score += delta
	update_score_display()
	if is_checked and sfx_complete and sfx_complete.stream:
		sfx_complete.play()
	request_save.emit()

func update_score_display():
	if current_view_day == actual_day:
		score_label.text = "🏆 目前累計分數: %d  |  🌟 本日總分: %d" % [total_accumulated_score, today_total_score]

func _on_add_task_pressed(): add_task_row()

# ==========================================
# 儲存 / 解鎖 / 結算
# ==========================================

# 💾 存檔節點：點擊「確認儲存」鎖定任務時
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
			TodoTaskRow.set_locked(row_data, true)

		# 任務確認儲存後存檔
		request_save.emit()
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
			TodoTaskRow.set_locked(row_data, false)

func _on_finish_pressed():
	total_accumulated_score += today_total_score
	update_score_display()
	finish_btn.disabled = true
	finish_btn.text = "已結算"
	toggle_save_btn.disabled = true
	for row_data in task_rows:
		row_data["checkbox"].disabled = true

func new_day_from_login():
	actual_day += 1
	current_view_day = actual_day
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
	update_day_navigation()
	update_score_display()
