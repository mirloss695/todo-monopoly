extends Node

const SAVE_KEY = "my_game_save"

# ==========================================
# 1. 儲存玩家進度 (上傳到雲端)
# ==========================================
func save_game_data():
	var main_node = get_node_or_null("/root/Main")
	if not main_node:
		print("⚠️ 找不到 Main 節點，取消儲存。")
		return
		
	var profile_node = main_node.get_node_or_null("UserProfile")
	
	var save_dict = {
		"global_score": main_node.global_score,
		"global_day": main_node.global_day,
		"global_stage": main_node.global_stage,
		"user_name": profile_node.user_name if profile_node else "新手玩家",
		"reward_item": profile_node.reward_item if profile_node else "豪華大餐一頓"
	}
	
	var payload = JSON.stringify(save_dict)
	print("☁️ 準備上傳存檔: ", payload)
	
	# 【最新官方 SDK 語法】儲存至 Player Storage 的 Key/Value
	var response = await LL_PlayerStorage.UpdateOrCreateKeyValue.new(SAVE_KEY, payload).send()
	
	if response.success:
		print("✅ 雲端存檔成功！")
	else:
		print("❌ 存檔失敗")

# ==========================================
# 2. 讀取玩家進度 (從雲端下載)
# ==========================================
func load_game_data():
	print("☁️ 開始下載雲端存檔...")
	
	# 【最新官方 SDK 語法】讀取 Player Storage 的 Key/Value
	var response = await LL_PlayerStorage.GetKeyValue.new(SAVE_KEY).send()
	
	# 這裡我們必須確認 response 成功，並且 payload 有值
	if response.success and response.payload != null and response.payload.value != "":
		var parsed_data = JSON.parse_string(response.payload.value)
		
		if typeof(parsed_data) == TYPE_DICTIONARY:
			print("✅ 讀取存檔成功，正在套用到遊戲...")
			_apply_save_data(parsed_data)
		else:
			print("❌ 存檔格式解析錯誤。")
	else:
		print("⚠️ 找不到雲端存檔 (可能是新帳號)，或讀取失敗。")

# ==========================================
# 3. 將下載的資料套用到遊戲節點
# ==========================================
func _apply_save_data(data: Dictionary):
	var main_node = get_node_or_null("/root/Main")
	if not main_node:
		return
		
	if data.has("global_score"): main_node.global_score = int(data["global_score"])
	if data.has("global_day"): main_node.global_day = int(data["global_day"])
	if data.has("global_stage"): main_node.global_stage = int(data["global_stage"])
		
	var profile_node = main_node.get_node_or_null("UserProfile")
	if profile_node:
		if data.has("user_name"): profile_node.user_name = data["user_name"]
		if data.has("reward_item"): profile_node.reward_item = data["reward_item"]
			
	if main_node.has_method("sync_all_data"):
		main_node.sync_all_data()
