extends Control
class_name TransitionController

var title = ""
var timer = 0.0
var duration = 0.8

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func play(text: String) -> void:
	title = text
	timer = duration
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if timer > 0.0:
		timer = max(0.0, timer - delta)
		if timer <= 0.0:
			visible = false
		queue_redraw()

func _draw() -> void:
	if timer <= 0.0:
		return
	var screen_size = get_viewport_rect().size
	var progress = 1.0 - timer / duration
	var alpha = 0.72 * (1.0 - abs(progress - 0.5))
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0, 0, 0, alpha))
	var bar = screen_size.x * min(1.0, progress * 1.65)
	draw_rect(Rect2(0, 0, bar, 42), Color8(88, 72, 58))
	draw_rect(Rect2(screen_size.x - bar, screen_size.y - 42, bar, 42), Color8(88, 72, 58))
	draw_line(Vector2(0, 42), Vector2(bar, 42), Color8(220, 172, 92), 3)
	draw_line(Vector2(screen_size.x - bar, screen_size.y - 42), Vector2(screen_size.x, screen_size.y - 42), Color8(220, 172, 92), 3)
	draw_string(ThemeDB.fallback_font, Vector2(0, screen_size.y * 0.5), title, HORIZONTAL_ALIGNMENT_CENTER, screen_size.x, 42, Color8(246, 236, 210))
