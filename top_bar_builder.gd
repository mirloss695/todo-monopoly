class_name TopBarBuilder
## 負責建構畫面左上角的按鈕列（帳號、切換地圖/任務）以及右下角的下一天按鈕

static func build(host: Control) -> Dictionary:
	var refs := {}

	# --- 左上角按鈕列 ---
	var top_bar = VBoxContainer.new()
	top_bar.position = Vector2(20, 20)
	top_bar.add_theme_constant_override("separation", 15)
	top_bar.z_index = 90
	host.add_child(top_bar)

	var profile_btn = Button.new()
	profile_btn.text = "👤"
	profile_btn.custom_minimum_size = Vector2(50, 50)
	profile_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	profile_btn.add_theme_font_size_override("font_size", 20)
	profile_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	profile_btn.mouse_entered.connect(func(): profile_btn.text = "👤 帳號資料")
	profile_btn.mouse_exited.connect(func(): profile_btn.text = "👤")
	top_bar.add_child(profile_btn)
	refs["profile_btn"] = profile_btn

	var switch_btn = Button.new()
	switch_btn.text = "🗺️"
	switch_btn.custom_minimum_size = Vector2(50, 50)
	switch_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	switch_btn.add_theme_font_size_override("font_size", 20)
	switch_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	top_bar.add_child(switch_btn)
	refs["switch_btn"] = switch_btn

	# --- 右下角「下一天」按鈕 ---
	var next_day_btn = Button.new()
	next_day_btn.text = "🌙 結束今天，進入下一天"
	next_day_btn.custom_minimum_size = Vector2(260, 60)
	next_day_btn.add_theme_font_size_override("font_size", 22)
	next_day_btn.set("theme_override_colors/font_color", Color.AQUAMARINE)
	next_day_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	host.add_child(next_day_btn)
	next_day_btn.hide()
	refs["next_day_btn"] = next_day_btn

	return refs
