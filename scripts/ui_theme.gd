class_name UiTheme
extends RefCounted
## Dark translucent theme for the settings overlay, built in code so it stays in one place.

const ACCENT := Color(1.0, 0.52, 0.16)
const ACCENT_SOFT := Color(1.0, 0.52, 0.16, 0.22)
const TEXT := Color(0.94, 0.93, 0.92)
const TEXT_DIM := Color(0.94, 0.93, 0.92, 0.6)
const PANEL_BG := Color(0.055, 0.05, 0.06, 0.9)
const CONTROL_BG := Color(1, 1, 1, 0.06)
const CONTROL_HOVER := Color(1, 1, 1, 0.1)
const HAIRLINE := Color(1, 1, 1, 0.09)
## Theme type variation for section headings ("MODE", "DISPLAY", ...).
const HEADER := "HeaderLabel"
const MENU := "MenuButtonRound"


static func build() -> Theme:
    var t := Theme.new()
    t.default_font_size = 17

    var panel := _box(PANEL_BG, 22)
    panel.border_color = HAIRLINE
    panel.set_border_width_all(1)
    panel.shadow_color = Color(0, 0, 0, 0.45)
    panel.shadow_size = 18
    panel.set_content_margin_all(10)
    t.set_stylebox("panel", "PanelContainer", panel)

    t.set_color("font_color", "Label", TEXT)
    t.set_type_variation(HEADER, "Label")
    t.set_color("font_color", HEADER, ACCENT)
    t.set_font_size("font_size", HEADER, 13)

    var normal := _box(CONTROL_BG, 12, 14, 10)
    var hover := _box(CONTROL_HOVER, 12, 14, 10)
    var pressed := _box(ACCENT_SOFT, 12, 14, 10)
    pressed.border_color = ACCENT
    pressed.set_border_width_all(1)
    var focus := StyleBoxEmpty.new()
    for type in ["Button", "OptionButton"]:
        t.set_stylebox("normal", type, normal)
        t.set_stylebox("hover", type, hover)
        t.set_stylebox("pressed", type, pressed)
        t.set_stylebox("hover_pressed", type, pressed)
        t.set_stylebox("disabled", type, _box(Color(1, 1, 1, 0.03), 12, 14, 10))
        t.set_stylebox("focus", type, focus)
        t.set_color("font_color", type, TEXT)
        t.set_color("font_hover_color", type, Color.WHITE)
        t.set_color("font_pressed_color", type, Color.WHITE)
        t.set_color("font_focus_color", type, TEXT)
        t.set_color("font_disabled_color", type, Color(1, 1, 1, 0.3))

    var flat := StyleBoxEmpty.new()
    flat.set_content_margin_all(6)
    t.set_stylebox("normal", "CheckBox", flat)
    t.set_stylebox("hover", "CheckBox", flat)
    t.set_stylebox("pressed", "CheckBox", flat)
    t.set_stylebox("hover_pressed", "CheckBox", flat)
    t.set_stylebox("disabled", "CheckBox", flat)
    t.set_color("font_disabled_color", "CheckBox", Color(1, 1, 1, 0.3))
    t.set_stylebox("focus", "CheckBox", focus)
    t.set_color("font_color", "CheckBox", TEXT)
    t.set_color("font_hover_color", "CheckBox", Color.WHITE)
    t.set_color("font_pressed_color", "CheckBox", Color.WHITE)
    t.set_color("font_focus_color", "CheckBox", TEXT)
    var on := _check_icon(26, true)
    var off := _check_icon(26, false)
    t.set_icon("checked", "CheckBox", on)
    t.set_icon("unchecked", "CheckBox", off)
    t.set_icon("checked_disabled", "CheckBox", on)
    t.set_icon("unchecked_disabled", "CheckBox", off)
    t.set_constant("h_separation", "CheckBox", 10)

    var track := _box(Color(1, 1, 1, 0.12), 4)
    track.content_margin_top = 3
    track.content_margin_bottom = 3
    var filled := _box(ACCENT, 4)
    filled.content_margin_top = 3
    filled.content_margin_bottom = 3
    t.set_stylebox("slider", "HSlider", track)
    t.set_stylebox("grabber_area", "HSlider", filled)
    t.set_stylebox("grabber_area_highlight", "HSlider", filled)
    t.set_icon("grabber", "HSlider", _dot(26, Color.WHITE))
    t.set_icon("grabber_highlight", "HSlider", _dot(26, Color(1, 0.86, 0.7)))

    var tab_selected := _box(ACCENT_SOFT, 10, 18, 8)
    var tab_idle := _box(Color(0, 0, 0, 0), 10, 18, 8)
    t.set_stylebox("tab_selected", "TabContainer", tab_selected)
    t.set_stylebox("tab_unselected", "TabContainer", tab_idle)
    t.set_stylebox("tab_hovered", "TabContainer", _box(CONTROL_BG, 10, 18, 8))
    t.set_stylebox("tab_focus", "TabContainer", focus)
    t.set_stylebox("panel", "TabContainer", StyleBoxEmpty.new())
    t.set_stylebox("tabbar_background", "TabContainer", StyleBoxEmpty.new())
    t.set_color("font_selected_color", "TabContainer", Color.WHITE)
    t.set_color("font_unselected_color", "TabContainer", TEXT_DIM)
    t.set_color("font_hovered_color", "TabContainer", TEXT)

    var line := StyleBoxLine.new()
    line.color = HAIRLINE
    line.thickness = 1
    t.set_stylebox("separator", "HSeparator", line)
    t.set_constant("separation", "HSeparator", 12)

    # A faint track and a bright thumb, wide enough to read as "this page scrolls".
    var bar := _box(Color(1, 1, 1, 0.05), 3, 3.0)
    var grab := _box(Color(1, 1, 1, 0.4), 3, 3.0)
    for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
        t.set_stylebox(state, "VScrollBar", grab)
    t.set_stylebox("scroll", "VScrollBar", bar)

    var popup := _box(Color(0.09, 0.085, 0.1, 0.98), 14)
    popup.set_content_margin_all(8)
    t.set_stylebox("panel", "PopupMenu", popup)
    t.set_stylebox("hover", "PopupMenu", _box(ACCENT_SOFT, 8))
    t.set_color("font_color", "PopupMenu", TEXT)
    t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
    t.set_constant("v_separation", "PopupMenu", 14)

    t.set_type_variation(MENU, "Button")
    var disc := _box(Color(0, 0, 0, 0.32), 40)
    disc.border_color = Color(1, 1, 1, 0.14)
    disc.set_border_width_all(1)
    var round_hover := disc.duplicate() as StyleBoxFlat
    round_hover.bg_color = Color(0, 0, 0, 0.5)
    t.set_stylebox("normal", MENU, disc)
    t.set_stylebox("hover", MENU, round_hover)
    t.set_stylebox("pressed", MENU, round_hover)
    t.set_stylebox("hover_pressed", MENU, round_hover)
    t.set_stylebox("focus", MENU, focus)
    t.set_color("font_color", MENU, Color(1, 1, 1, 0.85))
    return t


static func _box(color: Color, radius: int, margin_x: float = -1.0, margin_y: float = -1.0) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    box.set_corner_radius_all(radius)
    box.anti_aliasing = true
    if margin_x >= 0.0:
        box.content_margin_left = margin_x
        box.content_margin_right = margin_x
    if margin_y >= 0.0:
        box.content_margin_top = margin_y
        box.content_margin_bottom = margin_y
    return box


## Rounded box: outlined when off, accent-filled with a white tick when on.
static func _check_icon(size: int, checked: bool) -> ImageTexture:
    var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
    var half := float(size) * 0.5
    var radius := 6.0
    var tick_a := Vector2(size * 0.27, size * 0.52)
    var tick_b := Vector2(size * 0.43, size * 0.68)
    var tick_c := Vector2(size * 0.74, size * 0.34)
    for y in size:
        for x in size:
            var p := Vector2(x + 0.5, y + 0.5)
            # Signed distance to a rounded square inset by 1 px.
            var q := (p - Vector2(half, half)).abs() - Vector2(half - 1.0 - radius, half - 1.0 - radius)
            var box := q.max(Vector2.ZERO).length() + minf(maxf(q.x, q.y), 0.0) - radius
            var col := Color(0, 0, 0, 0)
            if checked:
                col = Color(ACCENT.r, ACCENT.g, ACCENT.b, clampf(0.5 - box, 0.0, 1.0))
                var tick := minf(_segment_distance(p, tick_a, tick_b), _segment_distance(p, tick_b, tick_c))
                var ink := clampf(1.8 - tick, 0.0, 1.0) * col.a
                col = Color(lerpf(col.r, 1.0, ink), lerpf(col.g, 1.0, ink), lerpf(col.b, 1.0, ink), col.a)
            else:
                col = Color(1, 1, 1, 0.6 * clampf(1.0 - absf(box + 0.75), 0.0, 1.0))
            img.set_pixel(x, y, col)
    return ImageTexture.create_from_image(img)


static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
    var ab := b - a
    var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
    return p.distance_to(a + ab * t)


static func _dot(size: int, color: Color) -> ImageTexture:
    var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
    var r := float(size) * 0.5
    for y in size:
        for x in size:
            var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
            var a := clampf(r - 1.0 - d, 0.0, 1.0)
            img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * a))
    return ImageTexture.create_from_image(img)
