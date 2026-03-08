class_name MapUIBuilder
## 負責建構 MapBoard 的 UI 面板（骰子按鈕、事件面板、升階面板）

static func build(host: Node2D) -> Dictionary:
	var refs := {}

	var ui_layer = CanvasLayer.new()
	host.add_child(ui_layer)
	refs["ui_layer"] = ui_layer

	# ── 骰子按鈕 ──
	var roll_dice_btn = Button.new()
	roll_dice_btn.text = "🎲 點擊擲骰子"
	roll_dice_btn.custom_minimum_size = Vector2(250, 80)
	roll_dice_btn.add_theme_font_size_override("font_size", 32)
	roll_dice_btn.set("theme_override_colors/font_color", Color.GOLD)
	roll_dice_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ui_layer.add_child(roll_dice_btn)
	roll_dice_btn.hide()
	refs["roll_dice_btn"] = roll_dice_btn

	# ── 一般事件面板 ──
	var event_panel = _build_event_panel(ui_layer)
	refs.merge(event_panel)

	# ── 升階確認面板 ──
	var stage_panel = _build_stage_panel(ui_layer)
	refs.merge(stage_panel)

	return refs

# ── 事件面板 ──

static func _build_event_panel(parent: CanvasLayer) -> Dictionary:
	var refs := {}

	var event_panel = ColorRect.new()
	event_panel.color = Color(0, 0, 0, 0.85)
	event_panel.size = Vector2(400, 200)
	parent.add_child(event_panel)

	var event_title = Label.new()
	event_title.text = "標題"
	event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_title.position = Vector2(0, 20)
	event_title.size = Vector2(400, 50)
	event_title.add_theme_font_size_override("font_size", 24)
	event_panel.add_child(event_title)

	var event_result = Label.new()
	event_result.text = "結果"
	event_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_result.position = Vector2(0, 75)
	event_result.size = Vector2(400, 100)
	event_result.add_theme_font_size_override("font_size", 48)
	event_panel.add_child(event_result)

	var continue_btn = Button.new()
	continue_btn.text = "確認並繼續"
	continue_btn.custom_minimum_size = Vector2(150, 40)
	continue_btn.position = Vector2((400 - 150) / 2.0, 145)
	continue_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	event_panel.add_child(continue_btn)
	continue_btn.hide()
	event_panel.hide()

	refs["event_panel"] = event_panel
	refs["event_title"] = event_title
	refs["event_result"] = event_result
	refs["continue_btn"] = continue_btn
	return refs

# ── 升階確認面板 ──

static func _build_stage_panel(parent: CanvasLayer) -> Dictionary:
	var refs := {}

	var stage_panel = ColorRect.new()
	stage_panel.color = Color(0, 0, 0, 0.90)
	stage_panel.size = Vector2(460, 260)
	parent.add_child(stage_panel)

	var sp_title = Label.new()
	sp_title.text = "🌀 抵達蟲洞！"
	sp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_title.position = Vector2(0, 18)
	sp_title.size = Vector2(460, 45)
	sp_title.add_theme_font_size_override("font_size", 26)
	sp_title.set("theme_override_colors/font_color", Color.GOLD)
	stage_panel.add_child(sp_title)

	var sp_desc = Label.new()
	sp_desc.name = "Desc"
	sp_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sp_desc.position = Vector2(20, 70)
	sp_desc.size = Vector2(420, 100)
	sp_desc.add_theme_font_size_override("font_size", 20)
	sp_desc.set("theme_override_colors/font_color", Color.WHITE)
	stage_panel.add_child(sp_desc)

	var sp_btn_hbox = HBoxContainer.new()
	sp_btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sp_btn_hbox.add_theme_constant_override("separation", 30)
	sp_btn_hbox.position = Vector2(0, 185)
	sp_btn_hbox.size = Vector2(460, 55)
	stage_panel.add_child(sp_btn_hbox)

	var stage_yes_btn = Button.new()
	stage_yes_btn.text = "✅ 前往下一階段"
	stage_yes_btn.custom_minimum_size = Vector2(180, 48)
	stage_yes_btn.add_theme_font_size_override("font_size", 20)
	stage_yes_btn.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	stage_yes_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	sp_btn_hbox.add_child(stage_yes_btn)

	var stage_no_btn = Button.new()
	stage_no_btn.text = "❌ 暫時不要"
	stage_no_btn.custom_minimum_size = Vector2(160, 48)
	stage_no_btn.add_theme_font_size_override("font_size", 20)
	stage_no_btn.set("theme_override_colors/font_color", Color.LIGHT_CORAL)
	stage_no_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	sp_btn_hbox.add_child(stage_no_btn)

	stage_panel.hide()

	refs["stage_panel"] = stage_panel
	refs["stage_yes_btn"] = stage_yes_btn
	refs["stage_no_btn"] = stage_no_btn
	return refs
