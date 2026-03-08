class_name CloudFileHelper
## 封裝 LootLocker Files API 的上傳、更新、列表、下載操作
## Files API 無 1500 字元限制，適合儲存大型 JSON 存檔
##
## 端點一覽：
##   列表  GET  /game/v1/player/files
##   上傳  POST /game/v1/player/files        (multipart/form-data)
##   更新  PUT  /game/v1/player/files/{id}   (multipart/form-data)
##   下載  直接 GET 回傳的 url 欄位

const LL_BASE_URL = "https://api.lootlocker.com"

# ==========================================
# 📋 列出玩家所有檔案
# 回傳 Array[Dictionary] 或空陣列（失敗時）
# 每筆 item: { "id": int, "name": String, "url": String, ... }
# ==========================================
static func list_files(host: Node, session_token: String) -> Array:
	var http = HTTPRequest.new()
	host.add_child(http)
	http.request(
		LL_BASE_URL + "/game/v1/player/files",
		_auth_headers(session_token),
		HTTPClient.METHOD_GET
	)
	var result = await http.request_completed
	http.queue_free()

	if result[1] != 200:
		push_warning("[CloudFileHelper] list_files 失敗，HTTP %d" % result[1])
		return []

	var parsed = JSON.parse_string(result[3].get_string_from_utf8())
	if parsed and parsed.has("items"):
		return parsed["items"]
	return []

# ==========================================
# 🔍 依檔名尋找第一個符合的 file_id
# 找不到回傳 -1
# ==========================================
static func find_file_id_by_name(host: Node, session_token: String, filename: String) -> int:
	var items = await list_files(host, session_token)
	for item in items:
		if item.get("name", "") == filename:
			return int(item["id"])
	return -1

# ==========================================
# ⬆️ 上傳新檔案（POST）
# 成功回傳新 file_id（int），失敗回傳 -1
# ==========================================
static func upload_file(host: Node, session_token: String, filename: String, content: String) -> int:
	var boundary = "GodotBoundary%d" % randi()
	var body = _build_multipart(boundary, filename, content)
	var headers = PackedStringArray([
		"Content-Type: multipart/form-data; boundary=" + boundary,
		"x-session-token: " + session_token
	])

	var http = HTTPRequest.new()
	host.add_child(http)
	http.request_raw(
		LL_BASE_URL + "/game/v1/player/files",
		headers,
		HTTPClient.METHOD_POST,
		body
	)
	var result = await http.request_completed
	http.queue_free()

	if result[1] != 200:
		push_warning("[CloudFileHelper] upload_file 失敗，HTTP %d" % result[1])
		push_warning("  回應：%s" % result[3].get_string_from_utf8())
		return -1

	var parsed = JSON.parse_string(result[3].get_string_from_utf8())
	if parsed and parsed.has("id"):
		return int(parsed["id"])
	return -1

# ==========================================
# ✏️ 更新現有檔案（PUT）
# 成功回傳 true，失敗回傳 false
# ==========================================
static func update_file(host: Node, session_token: String, file_id: int, filename: String, content: String) -> bool:
	var boundary = "GodotBoundary%d" % randi()
	var body = _build_multipart(boundary, filename, content)
	var headers = PackedStringArray([
		"Content-Type: multipart/form-data; boundary=" + boundary,
		"x-session-token: " + session_token
	])

	var http = HTTPRequest.new()
	host.add_child(http)
	http.request_raw(
		LL_BASE_URL + "/game/v1/player/files/%d" % file_id,
		headers,
		HTTPClient.METHOD_PUT,
		body
	)
	var result = await http.request_completed
	http.queue_free()

	if result[1] != 200:
		push_warning("[CloudFileHelper] update_file 失敗，HTTP %d" % result[1])
		push_warning("  回應：%s" % result[3].get_string_from_utf8())
		return false

	return true

# ==========================================
# ⬇️ 下載檔案內容（直接 GET 公開 URL）
# 成功回傳檔案字串，失敗回傳 ""
# ==========================================
static func download_file_by_url(host: Node, url: String) -> String:
	var http = HTTPRequest.new()
	host.add_child(http)
	http.request(url, PackedStringArray(), HTTPClient.METHOD_GET)
	var result = await http.request_completed
	http.queue_free()

	if result[1] != 200:
		push_warning("[CloudFileHelper] download_file 失敗，HTTP %d" % result[1])
		return ""

	return result[3].get_string_from_utf8()

# ==========================================
# 🔧 內部工具
# ==========================================

## 組合 multipart/form-data 封包（純 file 欄位）
static func _build_multipart(boundary: String, filename: String, content: String) -> PackedByteArray:
	var body := PackedByteArray()
	var crlf := "\r\n"

	body.append_array(("--%s%s" % [boundary, crlf]).to_utf8_buffer())
	body.append_array(('Content-Disposition: form-data; name="file"; filename="%s"%s' % [filename, crlf]).to_utf8_buffer())
	body.append_array(("Content-Type: application/json%s%s" % [crlf, crlf]).to_utf8_buffer())
	body.append_array(content.to_utf8_buffer())
	body.append_array(("%s--%s--%s" % [crlf, boundary, crlf]).to_utf8_buffer())

	return body

## 組合認證 Header（僅 JSON 用；multipart 需另外指定 Content-Type）
static func _auth_headers(session_token: String) -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"x-session-token: " + session_token
	])
