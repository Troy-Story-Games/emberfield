extends SceneTree
## Rasterizes icon/*.svg into the PNGs that Android export and the store listings need.
## Godot --headless --path . -s res://tools/make_icons.gd

const OUT := "res://icon/android/"


func _initialize() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    _render("res://icon/icon.svg", 192, OUT + "main_192.png")
    _render("res://icon/icon_foreground.svg", 432, OUT + "adaptive_foreground_432.png")
    _render("res://icon/icon_background.svg", 432, OUT + "adaptive_background_432.png")
    _monochrome("res://icon/icon_foreground.svg", 432, OUT + "adaptive_monochrome_432.png")
    _render("res://icon/icon.svg", 512, "res://fastlane/metadata/android/en-US/images/icon.png")
    _render("res://icon/icon.svg", 256, OUT + "splash_256.png")
    quit()


func _load(svg_path: String, size: int) -> Image:
    var img := Image.new()
    var svg := FileAccess.get_file_as_string(svg_path)
    var err := img.load_svg_from_string(svg, float(size) / 512.0)
    if err != OK:
        push_error("Could not render %s" % svg_path)
    return img


func _render(svg_path: String, size: int, out: String) -> void:
    var img := _load(svg_path, size)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
    img.save_png(out)
    print("wrote ", out)


## Android 13 themed icons: white silhouette, shape carried by alpha.
func _monochrome(svg_path: String, size: int, out: String) -> void:
    var img := _load(svg_path, size)
    img.convert(Image.FORMAT_RGBA8)
    for y in img.get_height():
        for x in img.get_width():
            var c := img.get_pixel(x, y)
            var lum := maxf(c.r, maxf(c.g, c.b))
            img.set_pixel(x, y, Color(1, 1, 1, c.a * clampf(lum * 1.4, 0.0, 1.0)))
    img.save_png(out)
    print("wrote ", out)
