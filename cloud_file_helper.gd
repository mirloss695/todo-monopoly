class_name CloudFileHelper
## 封裝 LootLocker Files API 的上傳、更新、列表、下載操作
##
## 官方文件修正（2024）：
##   ✅ 端點：/game/player/files（非 /game/v1/player/files）
##   ✅ 必要 header：LL-Version: 2021-03-01
##   ✅ 上傳必須附帶 purpose 欄位（multipart form field）
##   ✅ 更新端點：/game/player/files/{id}（PUT）

const LL_BASE_URL  = "https://api.lootlocker.com"
const LL_VERSION   = "2021-03-01"
const MAX_RETRIES  = 3
const RETRY_DELAY  = 1.5
const DOMAIN_KEY   = "mmdnk4rj"

# ==========================================
# 📋 列出玩家所有檔案
# ==========================================
static func list_files(host: Node, session_token: String) -> Array:
	print("[CloudFile] ▶ list_files 開始")
	print("[CloudFile]   token 前8碼：%s" % session_token.left(8))

	for attempt in range(MAX_RETRIES):
		print("[CloudFile]   list_files 第 %d 次嘗試..." % (attempt + 1))
		var http = HTTPRequest.new()
		host.add_child(http)
		http.request(
			LL_BASE_URL + "/game/player/files",
			_auth_headers(session_token),
			HTTPClient.METHOD_GET
		)
		var result = await http.request_completed
		http.queue_free()

		var code = result[1]
		var body = result[3].get_string_from_utf8()
		print("[CloudFile]   list_files HTTP %d，回應：%s" % [code, body])

		if code == 200:
			var parsed = JSON.parse_string(body)
			if parsed == null:
				push_warning("[CloudFile] ❌ list_files JSON 解析失敗")
				return []
			var items = parsed.get("items", parsed if parsed is Array else [])
			print("[CloudFile] ✅ list_files 成功，共 %d 個檔案" % items.size())
			for item in items:
				print("[CloudFile]     id=%-6d  name=%s" % [item.get("id", -1), item.get("name", "?")])
			return items

		push_warning("[CloudFile] ❌ list_files HTTP %d" % code)
		if attempt < MAX_RETRIES - 1:
			await host.get_tree().create_timer(RETRY_DELAY).timeout

	push_warning("[CloudFile] ❌ list_files 全部 %d 次嘗試失敗" % MAX_RETRIES)
	return []

# ==========================================
# 🔍 依檔名尋找完整 item（含最新 url）
# ==========================================
static func find_file_by_name(host: Node, session_token: String, filename: String) -> Dictionary:
	print("[CloudFile] ▶ find_file_by_name：%s" % filename)
	var items = await list_files(host, session_token)
	for item in items:
		if item.get("name", "") == filename:
			print("[CloudFile] ✅ 找到檔案 id=%d" % item["id"])
			return item
	print("[CloudFile]   找不到檔案：%s" % filename)
	return {}

# ==========================================
# 🔍 依檔名尋找 file_id
# ==========================================
static func find_file_id_by_name(host: Node, session_token: String, filename: String) -> int:
	var item = await find_file_by_name(host, session_token, filename)
	return int(item["id"]) if not item.is_empty() else -1

# ==========================================
# ⬆️  上傳新檔案（POST）
# 必要欄位：file（檔案內容）、purpose（用途字串）
# ==========================================
static func upload_file(host: Node, session_token: String, filename: String, content: String) -> int:
	print("[CloudFile] ▶ upload_file：%s（內容 %d 字元）" % [filename, content.length()])

	for attempt in range(MAX_RETRIES):
		print("[CloudFile]   upload_file 第 %d 次嘗試..." % (attempt + 1))
		var boundary = "----GodotBoundary%016d" % Time.get_ticks_msec()
		var body     = _build_multipart_upload(boundary, filename, content)
		var headers  = PackedStringArray([
			"Content-Type: multipart/form-data; boundary=" + boundary,
			"x-session-token: " + session_token,
			"LL-Version: " + LL_VERSION,
			"domain-key: " + DOMAIN_KEY
		])

		print("[CloudFile]   封包大小：%d bytes" % body.size())

		var http = HTTPRequest.new()
		host.add_child(http)
		http.request_raw(
			LL_BASE_URL + "/game/player/files",
			headers,
			HTTPClient.METHOD_POST,
			body
		)
		var result = await http.request_completed
		http.queue_free()

		var code = result[1]
		var resp = result[3].get_string_from_utf8()
		print("[CloudFile]   upload_file HTTP %d，回應：%s" % [code, resp])

		if code == 200 or code == 201:
			var parsed = JSON.parse_string(resp)
			if parsed and parsed.has("id"):
				print("[CloudFile] ✅ upload_file 成功，file_id=%d" % parsed["id"])
				return int(parsed["id"])
			push_warning("[CloudFile] ❌ upload_file 回應缺少 id 欄位")
			return -1

		push_warning("[CloudFile] ❌ upload_file HTTP %d" % code)
		if attempt < MAX_RETRIES - 1:
			await host.get_tree().create_timer(RETRY_DELAY).timeout

	push_warning("[CloudFile] ❌ upload_file 全部 %d 次嘗試失敗" % MAX_RETRIES)
	return -1

# ==========================================
# ✏️  更新現有檔案（PUT）
# ==========================================
static func update_file(host: Node, session_token: String, file_id: int, filename: String, content: String) -> bool:
	print("[CloudFile] ▶ update_file：id=%d，%s（內容 %d 字元）" % [file_id, filename, content.length()])

	for attempt in range(MAX_RETRIES):
		print("[CloudFile]   update_file 第 %d 次嘗試..." % (attempt + 1))
		var boundary = "----GodotBoundary%016d" % Time.get_ticks_msec()
		var body     = _build_multipart_update(boundary, filename, content)
		var headers  = PackedStringArray([
			"Content-Type: multipart/form-data; boundary=" + boundary,
			"x-session-token: " + session_token,
			"LL-Version: " + LL_VERSION,
			"domain-key: " + DOMAIN_KEY
		])

		print("[CloudFile]   封包大小：%d bytes" % body.size())

		var http = HTTPRequest.new()
		host.add_child(http)
		http.request_raw(
			LL_BASE_URL + "/game/player/files/%d" % file_id,
			headers,
			HTTPClient.METHOD_PUT,
			body
		)
		var result = await http.request_completed
		http.queue_free()

		var code = result[1]
		var resp = result[3].get_string_from_utf8()
		print("[CloudFile]   update_file HTTP %d，回應：%s" % [code, resp])

		if code == 200 or code == 201:
			print("[CloudFile] ✅ update_file 成功")
			return true

		push_warning("[CloudFile] ❌ update_file HTTP %d" % code)
		if attempt < MAX_RETRIES - 1:
			await host.get_tree().create_timer(RETRY_DELAY).timeout

	push_warning("[CloudFile] ❌ update_file 全部 %d 次嘗試失敗" % MAX_RETRIES)
	return false

# ==========================================
# ⬇️  下載檔案（GET Signed URL）
# ==========================================
static func download_file_by_url(host: Node, url: String) -> String:
	print("[CloudFile] ▶ download_file url 前60碼：%s..." % url.left(60))

	for attempt in range(MAX_RETRIES):
		print("[CloudFile]   download_file 第 %d 次嘗試..." % (attempt + 1))
		var http = HTTPRequest.new()
		host.add_child(http)
		http.request(url, PackedStringArray(), HTTPClient.METHOD_GET)
		var result = await http.request_completed
		http.queue_free()

		var code = result[1]
		var body = result[3].get_string_from_utf8()
		print("[CloudFile]   download_file HTTP %d，長度 %d 字元" % [code, body.length()])

		if code == 200:
			print("[CloudFile] ✅ download_file 成功，內容前100碼：%s" % body.left(100))
			return body

		push_warning("[CloudFile] ❌ download_file HTTP %d\n  回應：%s" % [code, body])
		if attempt < MAX_RETRIES - 1:
			await host.get_tree().create_timer(RETRY_DELAY).timeout

	push_warning("[CloudFile] ❌ download_file 全部 %d 次嘗試失敗" % MAX_RETRIES)
	return ""

# ==========================================
# 🔧 內部工具
# ==========================================

## 上傳用 multipart（含 file + purpose 兩個 part）
static func _build_multipart_upload(boundary: String, filename: String, content: String) -> PackedByteArray:
	var body := PackedByteArray()

	# ── part 1: file ──
	body.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
	body.append_array(("Content-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\n" % filename).to_utf8_buffer())
	body.append_array("Content-Type: application/octet-stream\r\n".to_utf8_buffer())
	body.append_array("\r\n".to_utf8_buffer())
	body.append_array(content.to_utf8_buffer())
	body.append_array("\r\n".to_utf8_buffer())

	# ── part 2: purpose ──
	body.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
	body.append_array("Content-Disposition: form-data; name=\"purpose\"\r\n".to_utf8_buffer())
	body.append_array("\r\n".to_utf8_buffer())
	body.append_array("save_game".to_utf8_buffer())
	body.append_array("\r\n".to_utf8_buffer())

	# ── closing boundary ──
	body.append_array(("--%s--\r\n" % boundary).to_utf8_buffer())
	return body

## 更新用 multipart（只需 file part，purpose 已在建立時設定）
static func _build_multipart_update(boundary: String, filename: String, content: String) -> PackedByteArray:
	var body := PackedByteArray()
	body.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
	body.append_array(("Content-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\n" % filename).to_utf8_buffer())
	body.append_array("Content-Type: application/octet-stream\r\n".to_utf8_buffer())
	body.append_array("\r\n".to_utf8_buffer())
	body.append_array(content.to_utf8_buffer())
	body.append_array("\r\n".to_utf8_buffer())
	body.append_array(("--%s--\r\n" % boundary).to_utf8_buffer())
	return body

static func _auth_headers(session_token: String) -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"x-session-token: " + session_token,
		"LL-Version: " + LL_VERSION,
		"domain-key: " + DOMAIN_KEY
	])
