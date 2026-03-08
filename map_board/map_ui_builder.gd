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
	
	# ── 開寶箱面板（第三階段完成） ──
	var chest_panel = _build_chest_panel(ui_layer)
	refs.merge(chest_panel)

	# ── 設定新獎勵面板 ──
	var new_reward_panel = _build_new_reward_panel(ui_layer)
	refs.merge(new_reward_panel)

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

# ── 開寶箱面板 ──

static func _build_chest_panel(parent: CanvasLayer) -> Dictionary:
	var refs := {}

	var chest_panel = ColorRect.new()
	chest_panel.color = Color(0, 0, 0, 0.92)
	chest_panel.size = Vector2(520, 340)
	parent.add_child(chest_panel)

	var title = Label.new()
	title.text = "🎉 恭喜完成所有階段！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 22)
	title.size = Vector2(520, 50)
	title.add_theme_font_size_override("font_size", 28)
	title.set("theme_override_colors/font_color", Color.GOLD)
	chest_panel.add_child(title)

	var chest_lbl = Label.new()
	chest_lbl.text = "🎁"
	chest_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest_lbl.position = Vector2(0, 78)
	chest_lbl.size = Vector2(520, 80)
	chest_lbl.add_theme_font_size_override("font_size", 64)
	chest_panel.add_child(chest_lbl)

	var reward_lbl = Label.new()
	reward_lbl.name = "ChestRewardDesc"
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_lbl.position = Vector2(20, 168)
	reward_lbl.size = Vector2(480, 90)
	reward_lbl.add_theme_font_size_override("font_size", 22)
	reward_lbl.set("theme_override_colors/font_color", Color.WHITE)
	chest_panel.add_child(reward_lbl)

	var claim_btn = Button.new()
	claim_btn.text = "🎊 領取獎勵！"
	claim_btn.custom_minimum_size = Vector2(200, 50)
	claim_btn.position = Vector2((520 - 200) / 2.0, 272)
	claim_btn.add_theme_font_size_override("font_size", 22)
	claim_btn.set("theme_override_colors/font_color", Color.GOLD)
	claim_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chest_panel.add_child(claim_btn)
	chest_panel.hide()

	refs["chest_panel"] = chest_panel
	refs["chest_reward_lbl"] = reward_lbl
	refs["chest_claim_btn"] = claim_btn
	return refs

# ── 設定新獎勵面板 ──

static func _build_new_reward_panel(parent: CanvasLayer) -> Dictionary:
	var refs := {}

	var new_reward_panel = ColorRect.new()
	new_reward_panel.color = Color(0, 0, 0, 0.92)
	new_reward_panel.size = Vector2(520, 300)
	parent.add_child(new_reward_panel)

	var title = Label.new()
	title.text = "🌀 重新出發！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 22)
	title.size = Vector2(520, 46)
	title.add_theme_font_size_override("font_size", 26)
	title.set("theme_override_colors/font_color", Color.GOLD)
	new_reward_panel.add_child(title)

	var desc = Label.new()
	desc.text = "你已回到第一階段起點，繼續努力吧！\n請設定下一個努力的獎勵目標（可留空）："
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(20, 76)
	desc.size = Vector2(480, 72)
	desc.add_theme_font_size_override("font_size", 18)
	desc.set("theme_override_colors/font_color", Color.LIGHT_GRAY)
	new_reward_panel.add_child(desc)

	var reward_edit = LineEdit.new()
	reward_edit.name = "NewRewardEdit"
	reward_edit.placeholder_text = "輸入新的獎勵目標（可留空）"
	reward_edit.position = Vector2(60, 162)
	reward_edit.size = Vector2(400, 48)
	reward_edit.add_theme_font_size_override("font_size", 20)
	reward_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_reward_panel.add_child(reward_edit)

	var confirm_btn = Button.new()
	confirm_btn.text = "✅ 確認，重新出發！"
	confirm_btn.custom_minimum_size = Vector2(230, 50)
	confirm_btn.position = Vector2((520 - 230) / 2.0, 232)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.set("theme_override_colors/font_color", Color.GREEN_YELLOW)
	confirm_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	new_reward_panel.add_child(confirm_btn)
	new_reward_panel.hide()

	refs["new_reward_panel"] = new_reward_panel
	refs["new_reward_edit"] = reward_edit
	refs["new_reward_confirm_btn"] = confirm_btn
	return refs
