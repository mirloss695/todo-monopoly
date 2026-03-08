extends Node
## 遊戲進度管理器
## 雲端存檔已從 Player Storage 遷移至 Files API
## ‣ 無 1500 字元限制
## ‣ 使用 cloud_file_helper.gd 封裝 multipart 上傳邏輯

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

# ==========================================
# 📁 Files API 快取
# ‣ _save_file_id > 0  → 已知檔案 ID，直接 PUT 更新
# ‣ _save_file_id == -1 → 尚未查詢 / 不存在，需 POST 建立
# ==========================================
const SAVE_FILENAME = "todo_save.json"
var _save_file_id: int = -1

# ==========================================
# ☁️ 雲端存檔（Files API）
## 流程：
##   1. 若 _save_file_id 未知 → 先查詢檔案清單
##   2. 找到舊檔 → PUT 更新；否則 POST 建立並快取新 ID
# ==========================================
func save_to_cloud() -> void:
	if session_token == "":
		push_warning("❌ [SaveManager] session_token 為空，無法存檔")
		return

	print("☁️ [SaveManager] 準備上傳存檔（Files API）...")

	var json_str = JSON.stringify(_build_save_dict())

	# ── 若尚未知道 file_id，先查一次清單 ──
	if _save_file_id <= 0:
		_save_file_id = await CloudFileHelper.find_file_id_by_name(self, session_token, SAVE_FILENAME)

	# ── 依結果選擇 PUT 或 POST ──
	if _save_file_id > 0:
		var ok = await CloudFileHelper.update_file(self, session_token, _save_file_id, SAVE_FILENAME, json_str)
		if ok:
			print("✅ [SaveManager] 雲端存檔更新成功！(file_id=%d)" % _save_file_id)
		else:
			push_warning("❌ [SaveManager] 雲端存檔更新失敗")
	else:
		var new_id = await CloudFileHelper.upload_file(self, session_token, SAVE_FILENAME, json_str)
		if new_id > 0:
			_save_file_id = new_id
			print("✅ [SaveManager] 雲端存檔建立成功！(file_id=%d)" % _save_file_id)
		else:
			push_warning("❌ [SaveManager] 雲端存檔建立失敗")

# ==========================================
# ☁️ 雲端讀檔（Files API）
## 回傳 true = 有存檔（老玩家），false = 新玩家
## 流程：
##   1. 列出檔案，尋找 todo_save.json
##   2. 取得其公開 URL 並下載 JSON 字串
##   3. 解析並還原各欄位
# ==========================================
func load_from_cloud() -> bool:
	if session_token == "":
		push_warning("❌ [SaveManager] session_token 為空，無法讀檔")
		return false

	print("☁️ [SaveManager] 從 Files API 下載存檔...")

	# ── 取得檔案清單，尋找目標檔案 ──
	var items = await CloudFileHelper.list_files(self, session_token)
	var target_url = ""

	for item in items:
		if item.get("name", "") == SAVE_FILENAME:
			_save_file_id = int(item["id"])
			target_url    = item.get("url", "")
			break

	if target_url == "":
		print("ℹ️ [SaveManager] 無存檔，以新玩家進度開始。")
		return false

	# ── 下載檔案內容 ──
	var raw = await CloudFileHelper.download_file_by_url(self, target_url)
	if raw == "":
		push_warning("❌ [SaveManager] 檔案內容為空或下載失敗")
		return false

	var save_parsed = JSON.parse_string(raw)
	if save_parsed == null:
		push_warning("❌ [SaveManager] JSON 解析失敗")
		return false

	# ── 還原各欄位 ──
	current_stage           = save_parsed.get("current_stage",           1)
	total_accumulated_score = save_parsed.get("total_accumulated_score", 0)
	actual_day              = save_parsed.get("actual_day",              1)
	map_tile_index          = save_parsed.get("map_tile_index",          0)
	map_move_direction      = save_parsed.get("map_move_direction",      1)
	user_name               = save_parsed.get("user_name",               "")
	reward_item             = save_parsed.get("reward_item",             "")

	var loaded_history = save_parsed.get("task_history", {})
	task_history.clear()
	for key in loaded_history:
		task_history[int(key)] = loaded_history[key]

	print("✅ [SaveManager] 讀檔成功！第 %d 天，file_id=%d" % [actual_day, _save_file_id])
	return true

# ==========================================
# 🔧 內部工具
# ==========================================

## 組合要儲存的 Dictionary
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
