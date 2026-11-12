extends CanvasLayer

# On-screen driving buttons. Supports several fingers at once.
# Other scripts read: steer (-1 left to 1 right), throttle (0 to 1), brake (0 to 1).

var steer := 0.0
var throttle := 0.0
var brake := 0.0

var _zones: Dictionary = {}
var _boxes: Dictionary = {}
var _touches: Dictionary = {}


func _ready() -> void:
    var screen: Vector2 = get_viewport().get_visible_rect().size
    var s := 190.0
    var m := 30.0
    var y: float = screen.y - s - m
    _add_zone("left", "<", Rect2(m, y, s, s))
    _add_zone("right", ">", Rect2(m * 2.0 + s, y, s, s))
    _add_zone("brake", "BRAKE", Rect2(screen.x - s * 2.0 - m * 2.0, y, s, s))
    _add_zone("gas", "GAS", Rect2(screen.x - s - m, y, s, s))


func _add_zone(zone_name: String, text: String, rect: Rect2) -> void:
    _zones[zone_name] = rect
    var box := ColorRect.new()
    box.position = rect.position
    box.size = rect.size
    box.color = Color(1.0, 1.0, 1.0, 0.2)
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(box)
    var label := Label.new()
    label.text = text
    label.set_anchors_preset(Control.PRESET_FULL_RECT)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 36)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(label)
    _boxes[zone_name] = box


func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touches[event.index] = _zone_at(event.position)
        else:
            _touches.erase(event.index)
        _refresh()
    elif event is InputEventScreenDrag:
        _touches[event.index] = _zone_at(event.position)
        _refresh()


func _zone_at(pos: Vector2) -> String:
    for zone_name in _zones:
        var rect: Rect2 = _zones[zone_name]
        if rect.has_point(pos):
            return zone_name
    return ""


func _refresh() -> void:
    var active: Array = _touches.values()
    steer = (1.0 if "right" in active else 0.0) - (1.0 if "left" in active else 0.0)
    throttle = 1.0 if "gas" in active else 0.0
    brake = 1.0 if "brake" in active else 0.0
    for zone_name in _boxes:
        var box: ColorRect = _boxes[zone_name]
        box.color = Color(1.0, 1.0, 1.0, 0.5 if zone_name in active else 0.2)
