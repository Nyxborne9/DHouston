extends Control
# Mars Colony - all numbers live in res://data/game_data.json

const BG := Color(0.17, 0.06, 0.04)
const PANEL := Color(0.27, 0.11, 0.07)
const ORANGE := Color(1.0, 0.62, 0.3)

var data: Dictionary = {}
var state: Dictionary = {}
var first_run := true
var rng := RandomNumberGenerator.new()
var content: VBoxContainer
var bars := {}
var bar_labels := {}
var info_label: Label
var log_label: Label
var action_box: VBoxContainer
var action_buttons: Array = []
var end_button: Button
var sol_label: Label


func _ready() -> void:
	rng.randomize()
	var txt := FileAccess.get_file_as_string("res://data/game_data.json")
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("game_data.json could not be read")
		return
	data = parsed
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	show_title()


func _label(text: String, size: int = 20, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(callback)
	return b


func _clear() -> void:
	for c in content.get_children():
		c.queue_free()
	bars.clear()
	bar_labels.clear()
	action_buttons.clear()


# ---------- screens ----------

func show_title() -> void:
	_clear()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(_label("MARS COLONY", 56, ORANGE))
	content.add_child(_label("A small colony on Mars needs you for %d sols." % int(data["sols"]), 24))
	content.add_child(_label("Each sol you have %d actions. Every action helps one thing and costs another, so choose carefully. Keep Power, Oxygen and Shield above zero and look after your 4 crew members.\n\nThe events in this game are based on real NASA data." % int(data["ap_per_sol"]), 20))
	content.add_child(_button("Start mission", start_game))


func start_game() -> void:
	state = data["start"].duplicate()
	state["sol"] = 1
	state["ap"] = int(data["ap_per_sol"])
	state["earth_reply"] = false
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	build_play_ui()
	begin_sol()


func build_play_ui() -> void:
	_clear()
	sol_label = _label("", 30, ORANGE)
	content.add_child(sol_label)
	for key in ["power", "oxygen", "shield"]:
		var row := HBoxContainer.new()
		var name_label := _label(key.capitalize(), 20)
		name_label.custom_minimum_size = Vector2(110, 0)
		name_label.size_flags_horizontal = Control.SIZE_FILL
		row.add_child(name_label)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(300, 24)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar)
		var val := _label("", 20)
		val.custom_minimum_size = Vector2(60, 0)
		val.size_flags_horizontal = Control.SIZE_FILL
		row.add_child(val)
		bars[key] = bar
		bar_labels[key] = val
		content.add_child(row)
	info_label = _label("", 20)
	content.add_child(info_label)
	log_label = _label("", 18, Color(1, 0.9, 0.75))
	content.add_child(log_label)
	action_box = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 6)
	content.add_child(action_box)
	for a in data["actions"]:
		var b := _button("%s   (%s)" % [a["label"], a["desc"]], _on_action.bind(a))
		action_box.add_child(b)
		action_buttons.append(b)
	end_button = _button("End sol", end_sol)
	content.add_child(end_button)


func refresh() -> void:
	sol_label.text = "Sol %d of %d" % [state["sol"], int(data["sols"])]
	for key in ["power", "oxygen", "shield"]:
		bars[key].value = state[key]
		bar_labels[key].text = str(int(state[key]))
	info_label.text = "Crew: %d    Science: %d    Actions left: %d" % [state["crew"], state["science"], state["ap"]]
	for b in action_buttons:
		b.disabled = state["ap"] <= 0


# ---------- game logic ----------

func apply_effects(effects: Dictionary, factor: float = 1.0) -> void:
	for k in effects:
		var amount: float = float(effects[k]) * factor
		state[k] = state[k] + int(round(amount))
		if k != "science":
			state[k] = clampi(state[k], 0, 100)


func begin_sol() -> void:
	state["ap"] = int(data["ap_per_sol"])
	var lines: Array = []
	if state["earth_reply"]:
		var lowest := "power"
		for key in ["oxygen", "shield"]:
			if state[key] < state[lowest]:
				lowest = key
		apply_effects({lowest: 5})
		lines.append("Earth replied! +5 %s." % lowest.capitalize())
		state["earth_reply"] = false
	var ev_id := _pick_event(int(state["sol"]))
	var ev: Dictionary = data["events"][ev_id]
	var factor := 1.0
	if ev.has("mitigation"):
		var m: Dictionary = ev["mitigation"]
		if state[m["resource"]] >= float(m["threshold"]):
			factor = float(m["factor"])
	apply_effects(ev["effects"], factor)
	lines.append("%s  %s" % [ev["title"].to_upper(), ev["text"]])
	lines.append("NASA fact: %s (%s)" % [ev["fact"], ev["source"]])
	log_label.text = "\n".join(lines)
	refresh()


func _pick_event(sol: int) -> String:
	if first_run:
		var key := str(sol)
		if data["fixed_schedule"].has(key):
			return data["fixed_schedule"][key]
		return "calm"
	var pool: Array = data["random_pool"]
	return pool[rng.randi_range(0, pool.size() - 1)]


func _on_action(a: Dictionary) -> void:
	if state["ap"] <= 0:
		return
	state["ap"] -= 1
	apply_effects(a["effects"])
	if a.get("earth_reply", false):
		state["earth_reply"] = true
	refresh()


func end_sol() -> void:
	apply_effects(data["daily"])
	var lost := 0
	var reasons: Array = []
	for key in ["power", "oxygen", "shield"]:
		if state[key] <= 0:
			lost += 1
			reasons.append(key)
	if lost > 0:
		state["crew"] = maxi(0, state["crew"] - lost)
	refresh()
	if state["crew"] <= 0:
		show_end(false, reasons)
		return
	if state["sol"] >= int(data["sols"]):
		show_end(true, reasons)
		return
	state["sol"] += 1
	begin_sol()
	if lost > 0:
		log_label.text = "%s hit zero last night. You lost %d crew member(s).\n\n%s" % [", ".join(reasons).capitalize(), lost, log_label.text]


func show_end(won: bool, reasons: Array) -> void:
	_clear()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	var score: int = int(state["science"]) + int(state["crew"]) * 10
	if won:
		content.add_child(_label("The colony survived!", 48, ORANGE))
		content.add_child(_label("You kept %d crew member(s) alive for %d sols." % [state["crew"], int(data["sols"])], 24))
	else:
		content.add_child(_label("The colony could not continue", 44, ORANGE))
		var why := ", ".join(reasons) if reasons.size() > 0 else "supplies"
		content.add_child(_label("Your resources ran out (%s) on sol %d. Real Mars crews plan carefully so this never happens. Try again and balance your actions!" % [why, state["sol"]], 22))
	content.add_child(_label("Score: %d   (Science %d + Crew x10)" % [score, state["science"]], 26))
	content.add_child(_label("Next game the events will be in a different order, just like real Mars weather.", 18))
	first_run = false
	content.add_child(_button("Play again", start_game))
