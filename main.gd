extends Node2D

const TILE := 48.0
const WORLD_W := 80
const WORLD_H := 18
const MAX_FPS := 120

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
            blocks[Vector2i(x, y)] = 2 if y > surface + 2 else 1
    # Small trees / landmarks.
    for x in [8, 23, 41, 63]:
        var ground := 11
        blocks[Vector2i(x, ground - 1)] = 3
        blocks[Vector2i(x, ground - 2)] = 3
        blocks[Vector2i(x - 1, ground - 2)] = 3
        blocks[Vector2i(x + 1, ground - 2)] = 3
        blocks[Vector2i(x, ground - 3)] = 3

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
    fps_label = "FPS %d   |   BLOCKVERSE v0.1" % Engine.get_frames_per_second()
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_active = true
            touch_origin = event.position
        else:
            touch_active = false
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _edit_block(event.position)
    elif event is InputEventScreenTouch and not event.pressed:
        _edit_block(event.position)

func _edit_block(screen_pos: Vector2) -> void:
    var world := (screen_pos.x + camera_x) / TILE
    var y := screen_pos.y / TILE
    var cell := Vector2i(floor(world), floor(y))
    if cell.y < 0 or cell.y >= WORLD_H:
        return
    if blocks.has(cell):
        blocks.erase(cell)
    else:
        if abs(cell.x - int(player.x)) <= 5 and abs(cell.y - int(player.y)) <= 4:
            blocks[cell] = selected_block

func _ground_at(x: float) -> float:
    var cell_x := int(floor(x))
    var best := WORLD_H - 1
    for y in range(WORLD_H):
        if blocks.has(Vector2i(cell_x, y)):
            best = y
            break
    return float(best)

func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("#08101c"))
    # Sky bands.
    draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.52)), Color("#123052"))
    draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.28)), Color("#1b4168"))

    for cell in blocks.keys():
        var p := Vector2(cell.x * TILE - camera_x, cell.y * TILE)
        if p.x < -TILE or p.x > size.x or p.y < -TILE or p.y > size.y:
            continue
        var c := Color("#4fbd67") if blocks[cell] == 1 else Color("#805c43")
        if blocks[cell] == 3:
            c = Color("#2d8b4a")
        draw_rect(Rect2(p + Vector2(1,1), Vector2(TILE-2, TILE-2)), c)
        draw_line(p + Vector2(0, TILE), p + Vector2(TILE, TILE), Color(0,0,0,0.18), 2.0)

    var pp := Vector2(player.x * TILE - camera_x, player.y * TILE)
    draw_rect(Rect2(pp - Vector2(16, 30), Vector2(32, 46)), Color("#e8d1a8"))
    draw_rect(Rect2(pp - Vector2(16, 30), Vector2(32, 14)), Color("#344fbd"))

    # HUD.
    draw_rect(Rect2(18, 18, 360, 70), Color(0,0,0,0.48), true)
    draw_string(ThemeDB.fallback_font, Vector2(34, 46), "BLOCKVERSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(34, 72), fps_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#a9d6ff"))
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 270, 40), "Touch: place / break", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 270, 64), "Arrows: move", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#a9d6ff"))
