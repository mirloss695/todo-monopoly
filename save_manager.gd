extends Node

# ==========================================
# 🧠 遊戲全域核心變數
# ==========================================
var current_stage = 1
var total_accumulated_score = 0
var task_history = {}
var actual_day = 1

const LL_BASE_URL = "https://api.lootlocker.io"

# ==========================================
# ☁️ LootLocker 雲端存檔邏輯
# ==========================================

# 1. 將資料打包並上傳至雲端
func save_to_cloud():
	print("☁️ [SaveManager] 準備上傳存檔至 LootLocker...")

	if not LL_StateData.IsLoggedIn():
		print("❌ [SaveManager] 尚未登入，無法存檔")
		return

	var save_data = {
		"current_stage": current_stage,
		"total_accumulated_score": total_accumulated_score,
		"task_history": task_history,
		"actual_day": actual_day
	}
	var json_string = JSON.stringify(save_data)

	var http = HTTPRequest.new()
	add_child(http)

	# LootLocker Player Storage API 接受一個 array
	var body = JSON.stringify([{"key": "todo_save", "value": json_string}])
	http.request(LL_BASE_URL + "/game/player/storage", _get_auth_headers(), HTTPClient.METHOD_POST, body)

	var result = await http.request_completed
	http.queue_free()

	if result[1] == 200:
		print("✅ [SaveManager] 雲端存檔成功！")
	else:
		print("❌ [SaveManager] 雲端存檔失敗，HTTP code: ", result[1])
		print("   回應內容: ", result[3].get_string_from_utf8())

# 2. 從雲端下載並解壓縮資料
func load_from_cloud():
	print("☁️ [SaveManager] 正在從 LootLocker 下載存檔...")

	if not LL_StateData.IsLoggedIn():
		print("ℹ️ [SaveManager] 尚未登入，略過雲端讀檔")
		return false

	var http = HTTPRequest.new()
	add_child(http)

	http.request(LL_BASE_URL + "/game/player/storage", _get_auth_headers(), HTTPClient.METHOD_GET)

	var result = await http.request_completed
	http.queue_free()

	if result[1] == 200:
		var parsed = JSON.parse_string(result[3].get_string_from_utf8())
		if parsed and parsed.get("payload"):
			for item in parsed["payload"]:
				if item["key"] == "todo_save":
					var save_parsed = JSON.parse_string(item["value"])
					if save_parsed:
						current_stage = save_parsed.get("current_stage", 1)
						total_accumulated_score = save_parsed.get("total_accumulated_score", 0)
						actual_day = save_parsed.get("actual_day", 1)

						var loaded_history = save_parsed.get("task_history", {})
						task_history.clear()
						for key in loaded_history:
							task_history[int(key)] = loaded_history[key]

						print("✅ [SaveManager] 讀檔成功！目前進度：第 ", actual_day, " 天。")
						return true

	print("ℹ️ [SaveManager] 找不到雲端存檔，將以新玩家進度開始。")
	return false

# ==========================================
# 🔧 內部工具：組合認證 Header
# ==========================================
func _get_auth_headers() -> PackedStringArray:
	var session_token = LootLockerInternal_LootLockerCache.current().get_data("session_token", "")
	return PackedStringArray([
		"Content-Type: application/json",
		"x-session-token: " + session_token
	])
