class_name CheatPanel
extends CanvasLayer
## 🛠️ 作弊面板（F12 開關）
## 功能：瞬移棋子、切換方向、修改分數、指定骰子點數、跳關

var map_board: Node2D
var main_ctrl: Control  # main.gd 的參照，用來同步 global_score

# --- UI 節點 ---
var panel: PanelContainer
var status_label: RichTextLabel

var tile_spin: SpinBox
var dir_btn: Button
var score_spin: SpinBox
var dice_spin: SpinBox
var stage_spin: SpinBox
var day_spin: SpinBox

var _is_visible := false

func _init():
	layer = 200  # 最上層

func setup(p_map_board: Node2D, p_main_ctrl: Control):
	map_board = p_map_board
	main_ctrl = p_main_ctrl
	_build_ui()
	panel.hide()

func _input(event):
	if event is InputEventKey and event.keycode == KEY_F12 and event.pressed and not event.echo:
		_is_visible = not _is_visible
		panel.visible = _is_visible
		if _is_visible:
			_refresh_status()

# ==========================================
# UI 建構
# ==========================================
func _build_ui():
	panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color.DARK_ORANGE
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# --- 標題 ---
	var title = Label.new()
	title.text = "🛠️ 作弊模式 (F12 關閉)"
	title.add_theme_font_size_override("font_size", 20)
	title.set("theme_override_colors/font_color", Color.DARK_ORANGE)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# --- 即時狀態 ---
	status_label = RichTextLabel.new()
	status_label.bbcode_enabled = true
	status_label.fit_content = true
	status_label.custom_minimum_size = Vector2(310, 80)
	status_label.add_theme_font_size_override("normal_font_size", 15)
	status_label.scroll_active = false
	vbox.add_child(status_label)

	vbox.add_child(HSeparator.new())

	# --- 瞬移到指定格子 ---
	tile_spin = SpinBox.new()
	tile_spin.min_value = 0
	tile_spin.max_value = 19
	tile_spin.value = 0
	_add_action_row(vbox, "🎯 瞬移到格子", tile_spin, "移動", _on_teleport)

	# --- 切換行進方向 ---
	dir_btn = Button.new()
	dir_btn.text = "→ 順時針"
	dir_btn.custom_minimum_size = Vector2(160, 36)
	dir_btn.add_theme_font_size_override("font_size", 16)
	dir_btn.set("theme_override_colors/font_color", Color.AQUAMARINE)
	dir_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dir_btn.pressed.connect(_on_toggle_direction)
	_add_label_row(vbox, "🔄 行進方向", dir_btn)

	# --- 修改累計分數 ---
	score_spin = SpinBox.new()
	score_spin.min_value = -99999
	score_spin.max_value = 99999
	score_spin.step = 100
	score_spin.value = 0
	_add_action_row(vbox, "💰 設定累計分數", score_spin, "套用", _on_set_score)

	# --- 指定骰子點數 ---
	dice_spin = SpinBox.new()
	dice_spin.min_value = 1
	dice_spin.max_value = 6
	dice_spin.value = 1
	_add_action_row(vbox, "🎲 指定骰子點數", dice_spin, "強制擲骰", _on_force_dice)

	# --- 跳階段 ---
	stage_spin = SpinBox.new()
	stage_spin.min_value = 1
	stage_spin.max_value = 10
	stage_spin.value = 1
	_add_action_row(vbox, "🌀 跳到階段", stage_spin, "跳階", _on_set_stage)

	# --- 跳天數 ---
	var day_hbox = HBoxContainer.new()
	day_hbox.add_theme_constant_override("separation", 8)

	var day_lbl = Label.new()
	day_lbl.text = "📅 天數跳躍"
	day_lbl.add_theme_font_size_override("font_size", 16)
	day_lbl.custom_minimum_size = Vector2(140, 0)
	day_hbox.add_child(day_lbl)

	var prev_day_btn = Button.new()
	prev_day_btn.text = "◀ 前一天"
	prev_day_btn.custom_minimum_size = Vector2(100, 34)
	prev_day_btn.add_theme_font_size_override("font_size", 14)
	prev_day_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	prev_day_btn.pressed.connect(_on_prev_day)
	day_hbox.add_child(prev_day_btn)

	var next_day_btn = Button.new()
	next_day_btn.text = "後一天 ▶"
	next_day_btn.custom_minimum_size = Vector2(100, 34)
	next_day_btn.add_theme_font_size_override("font_size", 14)
	next_day_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_day_btn.pressed.connect(_on_next_day)
	day_hbox.add_child(next_day_btn)

	vbox.add_child(day_hbox)

	# --- 面板定位在右上角 ---
	panel.position = Vector2(get_viewport().get_visible_rect().size.x - 380, 20)
	get_viewport().size_changed.connect(func():
		panel.position = Vector2(get_viewport().get_visible_rect().size.x - 380, 20)
	)

# ==========================================
# UI 工具
# ==========================================
func _add_action_row(parent: VBoxContainer, label_text: String, spin: SpinBox, btn_text: String, callback: Callable):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(lbl)

	spin.custom_minimum_size = Vector2(90, 0)
	hbox.add_child(spin)

	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(80, 34)
	btn.add_theme_font_size_override("font_size", 14)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(callback)
	hbox.add_child(btn)

	parent.add_child(hbox)

func _add_label_row(parent: VBoxContainer, label_text: String, content: Control):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(lbl)
	hbox.add_child(content)

	parent.add_child(hbox)

# ==========================================
# 狀態刷新
# ==========================================
func _refresh_status():
	if not map_board: return
	var dir_text = "順時針 →" if map_board.move_direction == 1 else "← 逆時針"
	var dir_color = "#7FFFD4" if map_board.move_direction == 1 else "#FF6347"
	status_label.text = (
		"[b]格子:[/b] %d / 19　[b]方向:[/b] [color=%s]%s[/color]\n" % [map_board.current_tile_index, dir_color, dir_text] +
		"[b]分數:[/b] %d　[b]階段:[/b] %d\n" % [map_board.total_score, map_board.current_stage] +
		"[b]天數:[/b] %d　[b]移動中:[/b] %s　[b]事件中:[/b] %s" % [
			main_ctrl.global_day,
			"是" if map_board.is_moving else "否",
			"是" if map_board.is_event_active else "否"
		]
	)
	# 同步 SpinBox 顯示值
	tile_spin.value = map_board.current_tile_index
	score_spin.value = map_board.total_score
	stage_spin.value = map_board.current_stage
	dir_btn.text = ("→ 順時針" if map_board.move_direction == 1 else "← 逆時針")

# ==========================================
# 作弊指令
# ==========================================
func _on_teleport():
	if not map_board or map_board.is_moving: return
	map_board.cheat_teleport_to(int(tile_spin.value))
	_refresh_status()

func _on_toggle_direction():
	if not map_board: return
	map_board.move_direction *= -1
	dir_btn.text = ("→ 順時針" if map_board.move_direction == 1 else "← 逆時針")
	_refresh_status()

func _on_set_score():
	if not map_board: return
	var new_score = int(score_spin.value)
	map_board.total_score = new_score
	main_ctrl.global_score = new_score
	main_ctrl._sync_all_data()
	_refresh_status()

func _on_force_dice():
	if not map_board: return
	# 強制顯示骰子按鈕並設定指定點數
	map_board.cheat_forced_dice_value = int(dice_spin.value)
	map_board.roll_dice_btn.show()
	_refresh_status()

func _on_set_stage():
	if not map_board: return
	var new_stage = int(stage_spin.value)
	map_board.current_stage = new_stage
	map_board.current_tile_index = 0
	map_board.chance_tiles = MapGenerator.generate_chance_tiles()
	map_board._rebuild_map()
	map_board._on_window_resized()
	main_ctrl.global_stage = new_stage
	main_ctrl._sync_all_data()
	_refresh_status()

func _on_prev_day():
	if not main_ctrl: return
	main_ctrl.cheat_advance_day(-1)
	_refresh_status()

func _on_next_day():
	if not main_ctrl: return
	main_ctrl.cheat_advance_day(1)
	_refresh_status()
