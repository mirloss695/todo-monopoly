extends Node
## 遊戲進度管理器
##
## 存檔策略（雙軌制）：
##   儲存：本機（user://todo_save.json）+ 雲端（Files API）同時寫入
##         雲端失敗不影響本機，進度永遠不會遺失
##   讀取：優先雲端（保持多裝置同步）→ 雲端失敗則 fallback 本機

# ==========================================
# 🧠 遊戲全域核心變數
# ==========================================
var current_stage = 1
var total_accumulated_score = 0
var task_history = {}
var actual_day = 1
var map_tile_index = 0
var map_move_direction = 1

var user_name = ""
var reward_item = ""

# ==========================================
# 🔑 Session Token
# ==========================================
var session_token = ""

# ==========================================
# 📁 快取
# ‣ _save_file_id：已知檔案 ID，用於 PUT 更新（避免每次存檔都先 GET 清單）
# ‣ URL 不快取：LootLocker Signed URL 有時效，每次讀檔都重新取
# ==========================================
const SAVE_FILENAME   = "todo_save.json"
var _save_file_id: int = -1

# ==========================================
# 💾 儲存（本機 + 雲端）
# ==========================================
func save_to_cloud() -> void:
	if session_token == "":
		push_warning("⚠️ [SaveManager] session_token 為空，略過雲端存檔")
		return

	print("☁️ [SaveManager] 上傳存檔至雲端...")
	var json_str = JSON.stringify(_build_save_dict())

	if _save_file_id <= 0:
		_save_file_id = await CloudFileHelper.find_file_id_by_name(self, session_token, SAVE_FILENAME)

	if _save_file_id > 0:
		var ok = await CloudFileHelper.update_file(self, session_token, _save_file_id, SAVE_FILENAME, json_str)
		if ok:
			print("✅ [SaveManager] 雲端存檔更新成功！(file_id=%d)" % _save_file_id)
		else:
			push_warning("❌ [SaveManager] 雲端存檔更新失敗（已重試 %d 次）" % CloudFileHelper.MAX_RETRIES)
	else:
		var new_id = await CloudFileHelper.upload_file(self, session_token, SAVE_FILENAME, json_str)
		if new_id > 0:
			_save_file_id = new_id
			print("✅ [SaveManager] 雲端存檔建立成功！(file_id=%d)" % _save_file_id)
		else:
			push_warning("❌ [SaveManager] 雲端存檔建立失敗（已重試 %d 次）" % CloudFileHelper.MAX_RETRIES)

# ==========================================
# 📂 讀取（雲端優先，失敗則 fallback 本機）
# 回傳 true = 有存檔，false = 新玩家
# ==========================================
func load_from_cloud() -> bool:
	if session_token == "":
		push_warning("❌ [SaveManager] session_token 為空，無法讀檔")
		return false

	var cloud_ok = await _load_cloud()
	if not cloud_ok:
		print("ℹ️ [SaveManager] 無雲端存檔，以新玩家進度開始")
	return cloud_ok
	
# ==========================================
# 🔧 雲端讀取（私有）
# ==========================================
func _load_cloud() -> bool:
	print("☁️ [SaveManager] 從 Files API 下載存檔...")

	# 每次讀檔都重新取最新 item（URL 是有時效的 Signed URL，不可重用）
	var item = await CloudFileHelper.find_file_by_name(self, session_token, SAVE_FILENAME)
	if item.is_empty():
		return false

	_save_file_id = int(item["id"])  # 順便更新快取
	var url: String = item.get("url", "")
	if url == "":
		push_warning("❌ [SaveManager] 檔案 item 缺少 url 欄位")
		return false

	var raw = await CloudFileHelper.download_file_by_url(self, url)
	if raw == "":
		return false

	var parsed = JSON.parse_string(raw)
	if parsed == null:
		push_warning("❌ [SaveManager] 雲端 JSON 解析失敗")
		return false

	_apply_save(parsed)
	print("✅ [SaveManager] 雲端讀檔成功（第 %d 天，file_id=%d）" % [actual_day, _save_file_id])
	return true

# ==========================================
# 🔧 共用工具
# ==========================================
func _build_save_dict() -> Dictionary:
	return {
		"current_stage":           current_stage,
		"total_accumulated_score": total_accumulated_score,
		"task_history":            task_history,
		"actual_day":              actual_day,
		"map_tile_index":          map_tile_index,
		"map_move_direction":      map_move_direction,
		"user_name":               user_name,
		"reward_item":             reward_item
	}

func _apply_save(data: Dictionary) -> void:
	current_stage           = int(data.get("current_stage",           1))
	total_accumulated_score = int(data.get("total_accumulated_score", 0))
	actual_day              = int(data.get("actual_day",              1))
	map_tile_index          = int(data.get("map_tile_index",          0))
	map_move_direction      = int(data.get("map_move_direction",      1))
	user_name               = data.get("user_name",               "")
	reward_item             = data.get("reward_item",             "")
	var loaded_history = data.get("task_history", {})
	task_history.clear()
	for key in loaded_history:
		task_history[int(key)] = loaded_history[key]
