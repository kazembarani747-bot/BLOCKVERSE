extends Node2D

# BLOCKVERSE 0.3 - 16x16 pixel-art voxel sandbox.
# Block textures are drawn on a 16x16 logical grid and scaled 3x on screen.
const PIXELS := 16
const TILE := 48.0
const WORLD_W := 100
const WORLD_H := 20
const MAX_FPS := 120

# Minecraft-inspired natural palette, with original BLOCKVERSE artwork.
const SKY_TOP := Color("#78b7e6")
const SKY_BOTTOM := Color("#c8e7f7")
const GRASS_TOP := Color("#70a83b")
const GRASS_SIDE := Color("#8a6a3f")
const DIRT := Color("#8b6845")
const STONE := Color("#7d7d7d")
const WOOD := Color("#9b6b3f")
const LEAF := Color("#4b8f3c")
const SAND := Color("#d8c27a")
const WATER := Color("#3f9bd1")

var player := Vector2(12.0, 9.0)
var velocity := Vector2.ZERO
var blocks: Dictionary = {}
var mobs: Array[Dictionary] = []
var selected_block := 2
var camera_x := 0.0
var touch_origin := Vector2.ZERO
var touch_active := false
var fps_label := ""

func _ready() -> void:
    Engine.max_fps = MAX_FPS
    _build_world()
    _spawn_mobs()
    queue_redraw()

func _build_world() -> void:
    for x in range(WORLD_W):
        var surface := 11 + int(sin(float(x) * 0.27) * 1.2)
        for y in range(surface, WORLD_H):
            if y == surface:
                blocks[Vector2i(x, y)] = 1
            elif y <= surface + 3:
                blocks[Vector2i(x, y)] = 2
            else:
                blocks[Vector2i(x, y)] = 3
    for x in [8, 23, 41, 63, 82]:
        var ground := 11
        for y in range(ground - 4, ground):
            blocks[Vector2i(x, y)] = 4
        for p in [Vector2i(x, ground - 5), Vector2i(x - 1, ground - 4), Vector2i(x + 1, ground - 4), Vector2i(x - 1, ground - 5), Vector2i(x + 1, ground - 5), Vector2i(x, ground - 6)]:
            blocks[p] = 5

func _spawn_mobs() -> void:
    mobs = [
        {"type": "cow", "pos": Vector2(30, 10.0), "dir": -1.0},
        {"type": "pig", "pos": Vector2(54, 10.0), "dir": 1.0},
        {"type": "cow", "pos": Vector2(74, 10.0), "dir": -1.0}
    ]

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
    for mob in mobs:
        mob.pos.x += mob.dir * delta * 0.35
        if mob.pos.x < 4 or mob.pos.x > WORLD_W - 4:
            mob.dir *= -1.0
        mob.pos.y = _ground_at(mob.pos.x) - 1.0
    camera_x = lerp(camera_x, player.x * TILE - get_viewport_rect().size.x * 0.45, min(1.0, delta * 8.0))
    camera_x = clamp(camera_x, 0.0, max(0.0, WORLD_W * TILE - get_viewport_rect().size.x))
    fps_label = "FPS %d   •   16×16 PIXELS   •   WORLD %d×%d" % [Engine.get_frames_per_second(), WORLD_W, WORLD_H]
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
        1: return GRASS_TOP
        2: return DIRT
        3: return STONE
        4: return WOOD
        5: return LEAF
        6: return SAND
        7: return WATER
        _: return Color("#aaaaaa")

func _px_rect(p: Vector2, gx: int, gy: int, gw: int, gh: int, c: Color) -> void:
    # One logical pixel is exactly 3 screen pixels: a crisp 16x16 texture grid.
    draw_rect(Rect2(p + Vector2(gx, gy) * 3.0, Vector2(gw, gh) * 3.0), c)

func _pixel_block(p: Vector2, kind: int) -> void:
    var base := _block_color(kind)
    draw_rect(Rect2(p, Vector2(TILE, TILE)), base)
    if kind == 1:
        _px_rect(p, 0, 0, 16, 4, Color("#79b43f"))
        _px_rect(p, 0, 4, 16, 12, DIRT)
        for q in [Vector2i(2, 7), Vector2i(6, 11), Vector2i(11, 6), Vector2i(13, 13)]:
            _px_rect(p, q.x, q.y, 1, 1, Color("#6e5036"))
    elif kind == 2:
        for q in [Vector2i(2, 3), Vector2i(7, 8), Vector2i(12, 5), Vector2i(4, 13), Vector2i(14, 12)]:
            _px_rect(p, q.x, q.y, 1, 1, Color("#6f5036"))
    elif kind == 3:
        for q in [Vector2i(2, 2), Vector2i(8, 5), Vector2i(12, 11), Vector2i(4, 13), Vector2i(14, 7)]:
            _px_rect(p, q.x, q.y, 2, 1, Color("#696969"))
    elif kind == 4:
        _px_rect(p, 2, 0, 12, 16, Color("#a97642"))
        _px_rect(p, 5, 0, 2, 16, Color("#7d512f"))
        _px_rect(p, 11, 0, 2, 16, Color("#c18a4d"))
    elif kind == 5:
        for q in [Vector2i(1, 2), Vector2i(5, 5), Vector2i(11, 2), Vector2i(13, 8), Vector2i(4, 12), Vector2i(10, 13)]:
            _px_rect(p, q.x, q.y, 2, 2, Color("#3e7d34"))
    elif kind == 6:
        for q in [Vector2i(3, 4), Vector2i(10, 9), Vector2i(13, 3)]:
            _px_rect(p, q.x, q.y, 1, 1, Color("#c3a960"))
    elif kind == 7:
        for q in [Vector2i(2, 4), Vector2i(8, 10), Vector2i(11, 5)]:
            _px_rect(p, q.x, q.y, 3, 1, Color("#63b9e8"))
    draw_rect(Rect2(p, Vector2(TILE, TILE)), Color(0, 0, 0, 0.14), false, 1.0)

func _draw_mob(mob: Dictionary) -> void:
    var p := Vector2(mob.pos.x * TILE - camera_x, mob.pos.y * TILE)
    var body := Color("#76543a") if mob.type == "cow" else Color("#e7a2a5")
    var dark := Color("#3f3025") if mob.type == "cow" else Color("#b86f78")
    # Original chunky voxel-animal silhouettes, using a 16px grid.
    _px_rect(p, -4, -5, 16, 7, body)
    _px_rect(p, -7, -3, 5, 6, body)
    _px_rect(p, -7, 1, 5, 2, dark)
    _px_rect(p, -2, 2, 3, 7, dark)
    _px_rect(p, 9, 2, 3, 7, dark)
    _px_rect(p, 0, -1, 2, 2, Color("#202020"))
    _px_rect(p, 5, -1, 2, 2, Color("#202020"))
    if mob.type == "cow":
        _px_rect(p, 2, -4, 3, 2, Color("#eee8dc"))
        _px_rect(p, 9, -3, 3, 2, Color("#eee8dc"))
    else:
        _px_rect(p, -5, -6, 2, 2, Color("#f0b0b3"))
        _px_rect(p, 10, -6, 2, 2, Color("#f0b0b3"))

func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), SKY_BOTTOM)
    draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.55)), SKY_TOP)
    draw_circle(Vector2(size.x * 0.78, 105), 34, Color("#fff1b0"))
    for cloud_x in [120.0, 520.0, 900.0]:
        var cx := fmod(cloud_x - camera_x * 0.12, size.x + 180.0) - 90.0
        draw_rect(Rect2(cx, 125, 120, 18), Color(1, 1, 1, 0.30))
        draw_rect(Rect2(cx + 20, 112, 54, 28), Color(1, 1, 1, 0.30))
    var hill_y := size.y * 0.48
    draw_colored_polygon(PackedVector2Array([Vector2(0, hill_y + 90), Vector2(180, hill_y), Vector2(360, hill_y + 80), Vector2(560, hill_y - 10), Vector2(760, hill_y + 75), Vector2(size.x, hill_y), Vector2(size.x, size.y), Vector2(0, size.y)]), Color("#5f8550"))

    for cell in blocks.keys():
        var p := Vector2(cell.x * TILE - camera_x, cell.y * TILE)
        if p.x < -TILE or p.x > size.x or p.y < -TILE or p.y > size.y:
            continue
        _pixel_block(p, blocks[cell])

    for mob in mobs:
        if mob.pos.x * TILE - camera_x > -100 and mob.pos.x * TILE - camera_x < size.x + 100:
            _draw_mob(mob)

    var pp := Vector2(player.x * TILE - camera_x, player.y * TILE)
    draw_rect(Rect2(pp + Vector2(-16, 17), Vector2(32, 7)), Color(0, 0, 0, 0.22))
    _px_rect(pp, -5, 5, 4, 5, Color("#28344d"))
    _px_rect(pp, 1, 5, 4, 5, Color("#28344d"))
    _px_rect(pp, -6, -4, 12, 7, Color("#3569d4"))
    _px_rect(pp, -5, -10, 10, 6, Color("#e5c39a"))
    _px_rect(pp, -5, -10, 10, 3, Color("#5a3925"))
    _px_rect(pp, -3, -7, 2, 2, Color("#1e2630"))
    _px_rect(pp, 2, -7, 2, 2, Color("#1e2630"))
    _px_rect(pp, -6, -4, 2, 5, Color("#e5c39a"))
    _px_rect(pp, 4, -4, 2, 5, Color("#e5c39a"))

    draw_rect(Rect2(14, 14, 455, 84), Color(0.02, 0.04, 0.08, 0.82))
    draw_rect(Rect2(18, 18, 447, 76), Color("#162640"), false, 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(34, 49), "BLOCKVERSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#f4e6bd"))
    draw_string(ThemeDB.fallback_font, Vector2(34, 77), fps_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d5efff"))
    draw_rect(Rect2(size.x - 300, 18, 282, 64), Color(0.02, 0.04, 0.08, 0.72))
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 280, 43), "TOUCH  •  BREAK / PLACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 280, 67), "←  →  MOVE   •   VOXEL MOBS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d5efff"))
    draw_rect(Rect2(18, size.y - 62, 250, 44), Color(0.02, 0.04, 0.08, 0.78))
    draw_string(ThemeDB.fallback_font, Vector2(34, size.y - 34), "16×16 PIXEL SANDBOX  •  v0.3", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f4e6bd"))
