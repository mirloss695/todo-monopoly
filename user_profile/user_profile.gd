extends Control
## 帳號面板主控制器
## UI 建構委託給 ProfileUIBuilder

var user_name = "新手玩家"
var total_score = 0
var current_stage = 1
var move_direction = 1
var play_days = 1
var reward_item = "豪華大餐一頓"

# UI 參照
var avatar_btn: TextureButton
var file_dialog: FileDialog
var name_input: LineEdit
var score_label: Label
var stage_label: RichTextLabel
var date_label: Label
var days_label: Label
var reward_prefix_label: Label
var reward_input: LineEdit
var close_btn: Button

func _ready():
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	self.z_index = 100
	_setup_ui()
	update_display()

func _setup_ui():
	var refs = ProfileUIBuilder.build(self)

	avatar_btn          = refs["avatar_btn"]
	file_dialog         = refs["file_dialog"]
	name_input          = refs["name_input"]
	score_label         = refs["score_label"]
	stage_label         = refs["stage_label"]
	date_label          = refs["date_label"]
	days_label          = refs["days_label"]
	reward_prefix_label = refs["reward_prefix_label"]
	reward_input        = refs["reward_input"]
	close_btn           = refs["close_btn"]

	name_input.text = user_name
	reward_input.text = reward_item

	# 連接信號
	name_input.text_changed.connect(_on_name_changed)
	reward_input.text_changed.connect(_on_reward_changed)
	avatar_btn.pressed.connect(_on_change_avatar_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	file_dialog.file_selected.connect(_on_file_selected)

func update_display():
	if name_input: name_input.text = user_name
	if reward_input: reward_input.text = reward_item

	score_label.text = str(total_score) + " 分"

	var direction_text = "靠近" if move_direction == 1 else "遠離"
	var highlight_color = "#32CD32" if move_direction == 1 else "#FF4500"
	stage_label.text = "現在是階段 %d，您正在 [color=%s]%s[/color] 蟲洞" % [current_stage, highlight_color, direction_text]

	var time = Time.get_date_dict_from_system()
	date_label.text = "%d 年 %02d 月 %02d 日" % [time.year, time.month, time.day]
	days_label.text = "您已經進行了 %d 天" % play_days

	var prefix = ""
	match current_stage:
		1: prefix = "遠在天邊的"
		2: prefix = "一點一點靠近的"
		3: prefix = "就快要抵達了的"
		_: prefix = "未知的"
	reward_prefix_label.text = prefix

func _on_name_changed(new_text: String):
	user_name = new_text
	SaveManager.user_name = new_text

func _on_reward_changed(new_text: String):
	reward_item = new_text
	SaveManager.reward_item = new_text

func _on_change_avatar_pressed(): file_dialog.popup_centered(Vector2(600, 400))

func _on_file_selected(path: String):
	var image = Image.new()
	if image.load(path) == OK:
		avatar_btn.texture_normal = ImageTexture.create_from_image(image)

func _on_close_pressed():
	self.hide()
