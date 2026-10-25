extends Node
class_name SolitudeManager

const NarrativeDataScript = preload("res://scripts/narrative/NarrativeData.gd")

signal changed
signal choice_started
signal choice_finished(choice_id)
signal continue_requested

var relationship := {}
var mood = "proud"
var active_level = -1
var level_time = 0.0
var beat_index = 0
var current_line := {}
var line_timer = 0.0
var choice_open = false
var choice_data := {}
var response_timer = 0.0
var completed_choice_levels := {}

func _ready() -> void:
	reset_run()

func reset_run() -> void:
	relationship = NarrativeDataScript.RELATIONSHIP_DEFAULTS.duplicate(true)
	mood = "proud"
	active_level = -1
	level_time = 0.0
	beat_index = 0
	current_line = {}
	line_timer = 0.0
	choice_open = false
	choice_data = {}
	response_timer = 0.0
	completed_choice_levels.clear()
	changed.emit()

func start_level(level_index: int) -> void:
	active_level = level_index
	level_time = 0.0
	beat_index = 0
	current_line = {}
	line_timer = 0.0
	choice_open = false
	choice_data = {}
	response_timer = 0.0
	changed.emit()

func tick(dt: float) -> void:
	line_timer = max(0.0, line_timer - dt)
	if response_timer > 0.0:
		response_timer -= dt
		if response_timer <= 0.0:
			current_line = {}
			changed.emit()
			continue_requested.emit()
		return
	if active_level != NarrativeDataScript.SOL_TEST_LEVEL or choice_open:
		return
	level_time += dt
	var beats = NarrativeDataScript.SOL_TEST_BEATS
	if beat_index < beats.size() and level_time >= float(beats[beat_index].time):
		show_line(beats[beat_index])
		beat_index += 1

func show_line(line: Dictionary, duration: float = 5.0) -> void:
	current_line = line.duplicate(true)
	line_timer = duration
	changed.emit()

func should_intercept_level_complete(level_index: int) -> bool:
	return level_index == NarrativeDataScript.SOL_TEST_LEVEL and not completed_choice_levels.has(level_index)

func begin_level_end_choice(level_index: int) -> void:
	if not should_intercept_level_complete(level_index):
		return
	choice_data = NarrativeDataScript.SOL_TEST_ENDING.duplicate(true)
	current_line = {"speaker": choice_data.get("speaker", "SOL"), "text": choice_data.get("text", "")}
	line_timer = 999.0
	choice_open = true
	changed.emit()
	choice_started.emit()

func choose(index: int) -> void:
	if not choice_open:
		return
	var choices: Array = choice_data.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	var effects: Dictionary = choice.get("effects", {})
	for key in effects.keys():
		relationship[key] = int(relationship.get(key, 0)) + int(effects[key])
	_update_mood()
	completed_choice_levels[active_level] = true
	choice_open = false
	current_line = {
		"speaker": choice_data.get("speaker", "SOL"),
		"text": String(choice.get("response", ""))
	}
	line_timer = 1.4
	response_timer = 1.05
	changed.emit()
	choice_finished.emit(String(choice.get("id", "")))

func state() -> Dictionary:
	return {
		"active": active_level == NarrativeDataScript.SOL_TEST_LEVEL or choice_open or line_timer > 0.0,
		"speaker": String(current_line.get("speaker", "")),
		"text": String(current_line.get("text", "")) if line_timer > 0.0 else "",
		"line_visible": line_timer > 0.0 and String(current_line.get("text", "")) != "",
		"choice_open": choice_open,
		"choices": choice_data.get("choices", []),
		"mood": mood
	}

func _update_mood() -> void:
	var warmth_score = int(relationship.get("trust", 0)) + int(relationship.get("warmth", 0))
	var hurt_score = int(relationship.get("hurt", 0)) + int(relationship.get("defiance", 0))
	var cold_score = int(relationship.get("apathy", 0)) + int(relationship.get("instability", 0))
	if cold_score >= 2:
		mood = "cold"
	elif hurt_score >= 2:
		mood = "defensive"
	elif warmth_score >= 2:
		mood = "warm"
	else:
		mood = "proud"
