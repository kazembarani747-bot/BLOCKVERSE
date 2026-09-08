extends Node2D

const TILE := 48.0
const WORLD_W := 80
const WORLD_H := 18
const MAX_FPS := 120

const SKY_TOP := Color("#0b1730")
const SKY_BOTTOM := Color("#24537a")
const GRASS := Color("#4fbd67")
const DIRT := Color("#805c43")
const STONE := Color("#687080")
const WOOD := Color("#8b633f")
const LEAF := Color("#2d8b4a")

var player := Vector2(12.0, 9.0)
var velocity := Vector2.ZERO
var blocks: Dictionary = {}
var selected_block := 1
var camera_x := 0.0
var touch_origin := Vector2.ZERO
var touch_active := false
var fps_label := ""

func _ready() -> void:
    Engine.max_fps = MAX_FPS
    _build_world()
    queue_redraw()

func _build_world() -> void:
    for x in range(WORLD_W):
        var surface := 11 + int(sin(float(x) * 0.35) * 1.5)
        for y in range(surface, WORLD_H):
            blocks[Vector2i(x, y)] = 2 if y <= surface + 2 else 4
    for x in [8, 23, 41, 63]:
        var ground := 11
        for y in range(ground - 3, ground):
            blocks[Vector2i(x, y)] = 3
        for p in [Vector2i(x, ground - 4), Vector2i(x - 1, ground - 3), Vector2i(x + 1, ground - 3), Vector2i(x - 1, ground - 4), Vector2i(x + 1, ground - 4)]:
            blocks[p] = 5

func _process(delta: float) -> void:
    var input_axis := Input.get_axis("ui_left", "ui_right")
    if abs(input_axis) < 0.01 and touch_active:
        input_axis = clamp((get_viewport().get_mouse_position().x - touch_origin.x) / 140.0, -1.0, 1.0)
    velocity.x = move_toward(velocity.x, input_axis * 6.0, delta * 18.0)
    velocity.y += 18.0 * delta
    player += velocity * delta
    player.x = clamp(player.x, 1.0, WORLD_W - 2.0)
    var floor_y := _ground_at(player.x)
    if player.y > floor_y - 0.9:
        player.y = floor_y - 0.9
        velocity.y = 0.0
    camera_x = lerp(camera_x, player.x * TILE - get_viewport_rect().size.x * 0.45, min(1.0, delta * 8.0))
    camera_x = clamp(camera_x, 0.0, max(0.0, WORLD_W * TILE - get_viewport_rect().size.x))
    fps_label = "FPS %d   •   WORLD 80×18" % Engine.get_frames_per_second()
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_active = true
            touch_origin = event.position
        else:
            touch_active = false
            _edit_block(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _edit_block(event.position)

func _edit_block(screen_pos: Vector2) -> void:
    var world := (screen_pos.x + camera_x) / TILE
    var y := screen_pos.y / TILE
    var cell := Vector2i(floor(world), floor(y))
    if cell.y < 0 or cell.y >= WORLD_H:
        return
    if blocks.has(cell):
        blocks.erase(cell)
    elif abs(cell.x - int(player.x)) <= 5 and abs(cell.y - int(player.y)) <= 4:
        blocks[cell] = selected_block

func _ground_at(x: float) -> float:
    var cell_x := int(floor(x))
    for y in range(WORLD_H):
        if blocks.has(Vector2i(cell_x, y)):
            return float(y)
    return float(WORLD_H - 1)

func _block_color(kind: int) -> Color:
    match kind:
        1: return GRASS
        2: return DIRT
        3: return WOOD
        4: return STONE
        5: return LEAF
        _: return Color("#9aa0aa")

func _pixel_block(p: Vector2, kind: int) -> void:
    var base := _block_color(kind)
    draw_rect(Rect2(p, Vector2(TILE, TILE)), base)
    draw_rect(Rect2(p, Vector2(TILE, 5)), base.lightened(0.16))
    draw_rect(Rect2(p, Vector2(5, TILE)), base.lightened(0.08))
    draw_rect(Rect2(p + Vector2(TILE - 5, 5), Vector2(5, TILE - 5)), base.darkened(0.18))
    draw_rect(Rect2(p + Vector2(5, TILE - 5), Vector2(TILE - 10, 5)), base.darkened(0.24))
    var seed := int(abs(p.x * 17.0 + p.y * 31.0)) % 4
    if kind == 2 or kind == 4:
        draw_rect(Rect2(p + Vector2(10 + seed * 5, 17), Vector2(4, 4)), base.darkened(0.16))
        draw_rect(Rect2(p + Vector2(30 - seed * 3, 31), Vector2(3, 3)), base.lightened(0.10))
    elif kind == 3:
        draw_rect(Rect2(p + Vector2(15, 0), Vector2(5, TILE)), base.darkened(0.12))
        draw_rect(Rect2(p + Vector2(33, 0), Vector2(4, TILE)), base.lightened(0.08))
    elif kind == 5:
        draw_rect(Rect2(p + Vector2(10, 11), Vector2(7, 7)), base.lightened(0.12))
        draw_rect(Rect2(p + Vector2(29, 28), Vector2(6, 6)), base.darkened(0.12))

func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), SKY_BOTTOM)
    draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.55)), SKY_TOP)
    draw_circle(Vector2(size.x * 0.78, 105), 34, Color("#f5d889"))
    # Pixel-style clouds and distant hills.
    for cloud_x in [120.0, 520.0, 900.0]:
        var cx := fmod(cloud_x - camera_x * 0.12, size.x + 180.0) - 90.0
        draw_rect(Rect2(cx, 125, 120, 18), Color(1, 1, 1, 0.10))
        draw_rect(Rect2(cx + 20, 112, 54, 28), Color(1, 1, 1, 0.10))
    var hill_y := size.y * 0.48
    draw_colored_polygon(PackedVector2Array([Vector2(0, hill_y + 90), Vector2(180, hill_y), Vector2(360, hill_y + 80), Vector2(560, hill_y - 10), Vector2(760, hill_y + 75), Vector2(size.x, hill_y), Vector2(size.x, size.y), Vector2(0, size.y)]), Color("#172d3b"))

    for cell in blocks.keys():
        var p := Vector2(cell.x * TILE - camera_x, cell.y * TILE)
        if p.x < -TILE or p.x > size.x or p.y < -TILE or p.y > size.y:
            continue
        _pixel_block(p, blocks[cell])

    var pp := Vector2(player.x * TILE - camera_x, player.y * TILE)
    # Pixel-art player: shadow, boots, body, hair, face and shirt highlights.
    draw_rect(Rect2(pp + Vector2(-16, 17), Vector2(32, 7)), Color(0, 0, 0, 0.22))
    draw_rect(Rect2(pp + Vector2(-14, 5), Vector2(11, 16)), Color("#273044"))
    draw_rect(Rect2(pp + Vector2(3, 5), Vector2(11, 16)), Color("#273044"))
    draw_rect(Rect2(pp + Vector2(-16, -12), Vector2(32, 21)), Color("#355bd0"))
    draw_rect(Rect2(pp + Vector2(-13, -29), Vector2(26, 18)), Color("#e8d1a8"))
    draw_rect(Rect2(pp + Vector2(-13, -29), Vector2(26, 7)), Color("#513622"))
    draw_rect(Rect2(pp + Vector2(-8, -18), Vector2(4, 4)), Color("#18202d"))
    draw_rect(Rect2(pp + Vector2(4, -18), Vector2(4, 4)), Color("#18202d"))
    draw_rect(Rect2(pp + Vector2(-15, -12), Vector2(4, 16)), Color("#e8d1a8"))
    draw_rect(Rect2(pp + Vector2(11, -12), Vector2(4, 16)), Color("#e8d1a8"))

    # HUD with pixel-style panels.
    draw_rect(Rect2(14, 14, 390, 82), Color(0.02, 0.04, 0.08, 0.82))
    draw_rect(Rect2(18, 18, 382, 74), Color("#162640"), false, 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(34, 49), "BLOCKVERSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#f4e6bd"))
    draw_string(ThemeDB.fallback_font, Vector2(34, 77), fps_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#9fd7ff"))
    draw_rect(Rect2(size.x - 285, 18, 267, 64), Color(0.02, 0.04, 0.08, 0.72))
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 265, 43), "TOUCH  •  BREAK / PLACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 265, 67), "←  →  MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9fd7ff"))
    draw_rect(Rect2(18, size.y - 62, 220, 44), Color(0.02, 0.04, 0.08, 0.78))
    draw_string(ThemeDB.fallback_font, Vector2(34, size.y - 34), "PIXEL SANDBOX  •  v0.2", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f4e6bd"))
