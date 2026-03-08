class_name MapEvents
## 負責地圖事件：骰子動畫、機會轉盤、終點升階判定

## 骰子動畫：在 event_panel 上快速切換數字，回傳最終點數
static func animate_dice(event_panel: ColorRect, event_title: Label, event_result: Label, tree: SceneTree) -> int:
	event_panel.show()
	event_title.text = "🎲 擲骰子中..."

	for i in range(8):
		event_result.text = str(randi_range(1, 6))
		await tree.create_timer(0.03).timeout

	var final_roll = randi_range(1, 6)
	event_result.text = str(final_roll) + " 步！"
	return final_roll

## 機會轉盤動畫 + 結果判定
## 回傳 Dictionary: { "type": "move_forward"|"move_backward"|"add_score"|"sub_score", "value": int }
static func animate_chance_wheel(
	event_panel: ColorRect,
	event_title: Label,
	event_result: Label,
	current_stage: int,
	tree: SceneTree
) -> Dictionary:
	event_panel.show()
	event_title.text = "✨ 機會與命運轉盤 ✨"
	var options = ["前進 ?", "後退 ?", "加分 !", "扣分 !"]

	for i in range(12):
		event_result.text = options[randi() % 4]
		await tree.create_timer(0.03).timeout

	var final_option = randi() % 4 + 1
	var n = 0; var m = 0; var result_text = ""
	var m_base = 450 * current_stage
	var m_variance = 50 * current_stage

	match final_option:
		1: n = randi_range(1, 6); result_text = "前進 " + str(n) + " 格！"
		2: n = randi_range(1, 6); result_text = "後退 " + str(n) + " 格！"
		3: m = randi_range(m_base - m_variance, m_base + m_variance); result_text = "加 " + str(m) + " 分！"
		4: m = randi_range(m_base - m_variance, m_base + m_variance); result_text = "減 " + str(m) + " 分！"

	event_result.text = result_text

	var type_map = {1: "move_forward", 2: "move_backward", 3: "add_score", 4: "sub_score"}
	var value = n if final_option <= 2 else m
	return {"type": type_map[final_option], "value": value}

## 判定終點格狀態
## 回傳: "no_threshold" | "insufficient" | "ask_player"
static func evaluate_end_tile(total_score: int, current_stage: int, stage_thresholds: Dictionary) -> String:
	var threshold = stage_thresholds.get(current_stage, 0)
	if threshold == 0:
		return "no_threshold"
	if total_score < threshold:
		return "insufficient"
	return "ask_player"

## 取得升階門檻分數
static func get_threshold(current_stage: int, stage_thresholds: Dictionary) -> int:
	return stage_thresholds.get(current_stage, 0)
