class_name MapGenerator
## 負責生成地圖格子、機會格、以及玩家棋子

const TILE_SIZE = Vector2(120, 94)
const OFFSET = Vector2(10, 10)

const SPIRAL_PATH = [
	Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0),
	Vector2(3, 1), Vector2(3, 2), Vector2(3, 3), Vector2(3, 4),
	Vector2(2, 4), Vector2(1, 4), Vector2(0, 4),
	Vector2(0, 3), Vector2(0, 2), Vector2(0, 1),
	Vector2(1, 1), Vector2(2, 1),
	Vector2(2, 2), Vector2(2, 3),
	Vector2(1, 3),
	Vector2(1, 2)
]

## 隨機產生 3 個機會格位置（彼此間距至少 3 格）
static func generate_chance_tiles() -> Array:
	var chance_tiles = []
	var valid_range = range(1, 19)
	while chance_tiles.size() < 3:
		var pick = valid_range[randi() % valid_range.size()]
		var is_valid = true
		for existing in chance_tiles:
			if abs(pick - existing) <= 3:
				is_valid = false
				break
		if is_valid: chance_tiles.append(pick)
	chance_tiles.sort()
	return chance_tiles

## 產生地圖格子，回傳 map_tiles 陣列
static func generate_map(parent: Node2D, chance_tiles: Array, current_stage: int, stage_thresholds: Dictionary) -> Array:
	var map_tiles = []
	var start_pos = Vector2(0, 0)

	for i in range(SPIRAL_PATH.size()):
		var grid_pos = SPIRAL_PATH[i]
		var tile = Panel.new()
		tile.size = TILE_SIZE
		tile.position = start_pos + Vector2(grid_pos.x * (TILE_SIZE.x + OFFSET.x), grid_pos.y * (TILE_SIZE.y + OFFSET.y))

		var style = _create_tile_style(i, chance_tiles)
		tile.add_theme_stylebox_override("panel", style)
		parent.add_child(tile)

		var label = _create_tile_label(i, chance_tiles, current_stage, stage_thresholds)
		tile.add_child(label)
		map_tiles.append(tile)

	return map_tiles

## 建立玩家棋子
static func create_player(parent: Node2D, map_tiles: Array, tile_index: int) -> Panel:
	var player_node = Panel.new()
	player_node.size = Vector2(56, 56)
	var style = StyleBoxFlat.new()
	style.bg_color = Color.DODGER_BLUE
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	player_node.add_theme_stylebox_override("panel", style)

	player_node.position = map_tiles[tile_index].position + (TILE_SIZE - player_node.size) / 2.0
	player_node.z_index = 10
	parent.add_child(player_node)
	return player_node

# ── 內部工具 ──

static func _create_tile_style(i: int, chance_tiles: Array) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 4)

	if i == 0: style.bg_color = Color("#FFDD44")
	elif i == SPIRAL_PATH.size() - 1: style.bg_color = Color("#00AEEF")
	elif i in chance_tiles: style.bg_color = Color("#A366FF")
	else: style.bg_color = Color.LIGHT_GRAY

	return style

static func _create_tile_label(i: int, chance_tiles: Array, current_stage: int, stage_thresholds: Dictionary) -> Label:
	var label = Label.new()

	if i == SPIRAL_PATH.size() - 1:
		var threshold = stage_thresholds.get(current_stage, 0)
		label.text = "蟲洞\n(%d分)" % threshold if threshold > 0 else "蟲洞\n(終點)"
	elif i == 0: label.text = "開始⮕"
	elif i in chance_tiles: label.text = "機會與\n命運"
	else: label.text = str(i)

	label.set("theme_override_colors/font_color", Color.WHITE if i in chance_tiles else Color.BLACK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 20)
	return label
