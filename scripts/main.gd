extends Control
## Web build smoke test. This scene only proves that the game starts in the
## browser, shows text and reacts to clicks. It will be replaced by the real
## Mars Colony game.

var clicks: int = 0
var clicks_label: Label


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.17, 0.06, 0.04)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	box.add_child(_make_label("MARS COLONY", 56))
	box.add_child(_make_label("Web build test", 24))

	var platform_name: String = "web" if OS.has_feature("web") else OS.get_name()
	var version_text: String = Engine.get_version_info()["string"]
	box.add_child(_make_label("Godot %s | running on: %s" % [version_text, platform_name], 18))

	var button := Button.new()
	button.text = "Click me"
	button.custom_minimum_size = Vector2(240, 56)
	button.pressed.connect(_on_button_pressed)
	box.add_child(button)

	clicks_label = _make_label("Clicks: 0", 24)
	box.add_child(clicks_label)


func _make_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	return label


func _on_button_pressed() -> void:
	clicks += 1
	clicks_label.text = "Clicks: %d" % clicks
