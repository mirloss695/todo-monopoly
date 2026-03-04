extends Node

# ==========================================
# 🧠 遊戲全域核心變數
# ==========================================
var current_stage = 1
var total_accumulated_score = 0
var task_history = {}
var actual_day = 1
var map_tile_index = 0
var map_move_direction = 1

# 帳號面板資料
var user_name = ""
var reward_item = ""

# ==========================================
# 🔑 Session Token（登入後由 login.gd 設定）
# ==========================================
var session_token = ""

const LL_BASE_URL = "https://api.lootlocker.com"

# ==========================================
# ☁️ 雲端存檔（Player Storage via REST API）
# ==========================================

func save_to_cloud():
	if session_token == "":
		print("❌ [SaveManager] session_token 為空，無法存檔")
		return

	print("☁️ [SaveManager] 準備上傳存檔...")

	var save_data = {
		"current_stage": current_stage,
		"total_accumulated_score": total_accumulated_score,
		"task_history": task_history,
		"actual_day": actual_day,
		"map_tile_index": map_tile_index,
		"map_move_direction": map_move_direction,
		"user_name": user_name,
		"reward_item": reward_item
	}

	var body = JSON.stringify({"payload": [{"key": "todo_save", "value": JSON.stringify(save_data), "is_public": false, "order": 1}]})

	var http = HTTPRequest.new()
	add_child(http)
	http.request(
		LL_BASE_URL + "/game/v1/player/storage",
		_get_auth_headers(),
		HTTPClient.METHOD_POST,
		body
	)
	var result = await http.request_completed
	http.queue_free()

	if result[1] == 200:
		print("✅ [SaveManager] 雲端存檔成功！")
	else:
		print("❌ [SaveManager] 雲端存檔失敗，HTTP code: ", result[1])
		print("   回應: ", result[3].get_string_from_utf8())

# 回傳 true = 有存檔（老玩家），false = 新玩家
func load_from_cloud() -> bool:
	if session_token == "":
		print("❌ [SaveManager] session_token 為空，無法讀檔")
		return false

	print("☁️ [SaveManager] 正在從雲端下載存檔...")

	var http = HTTPRequest.new()
	add_child(http)
	http.request(
		LL_BASE_URL + "/game/v1/player/storage",
		_get_auth_headers(),
		HTTPClient.METHOD_GET
	)
	var result = await http.request_completed
	http.queue_free()

	if result[1] != 200:
		print("❌ [SaveManager] 讀檔失敗，HTTP code: ", result[1])
		return false

	var parsed = JSON.parse_string(result[3].get_string_from_utf8())
	if parsed and parsed.get("payload"):
		for item in parsed["payload"]:
			if item.get("key", "") == "todo_save":
				var save_parsed = JSON.parse_string(item.get("value", ""))
				if save_parsed:
					current_stage           = save_parsed.get("current_stage", 1)
					total_accumulated_score = save_parsed.get("total_accumulated_score", 0)
					actual_day              = save_parsed.get("actual_day", 1)
					map_tile_index          = save_parsed.get("map_tile_index", 0)
					map_move_direction      = save_parsed.get("map_move_direction", 1)
					user_name               = save_parsed.get("user_name", "")
					reward_item             = save_parsed.get("reward_item", "")

					var loaded_history = save_parsed.get("task_history", {})
					task_history.clear()
					for key in loaded_history:
						task_history[int(key)] = loaded_history[key]

					print("✅ [SaveManager] 讀檔成功！第 ", actual_day, " 天。")
					return true

	print("ℹ️ [SaveManager] 無存檔，以新玩家進度開始。")
	return false

# ==========================================
# 🔧 內部工具：組合認證 Header
# ==========================================
func _get_auth_headers() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"x-session-token: " + session_token
	])
