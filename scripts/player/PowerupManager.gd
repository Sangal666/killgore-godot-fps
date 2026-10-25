extends Node
class_name PowerupManager

signal changed

var powerups = {}
var timers = {"berserk": 0.0, "haste": 0.0, "shield": 0.0}

func configure(powerup_data: Dictionary) -> void:
	powerups = powerup_data
	timers = {"berserk": 0.0, "haste": 0.0, "shield": 0.0}
	changed.emit()

func tick(dt: float) -> void:
	var did_change = false
	for key in timers.keys():
		var before = timers[key]
		timers[key] = max(0.0, timers[key] - dt)
		if before != timers[key]:
			did_change = true
	if did_change:
		changed.emit()

func apply_powerup(id: String) -> void:
	if not powerups.has(id):
		return
	var data = powerups[id]
	timers[id] = data.duration
	changed.emit()

func active_text() -> String:
	var active = "NONE"
	var best = 0.0
	for key in timers.keys():
		if timers[key] > best:
			best = timers[key]
			active = "%s %d" % [key.substr(0, 3).to_upper(), int(best)]
	return active

func speed_multiplier() -> float:
	return powerups.haste.speed_multiplier if timers.haste > 0.0 else 1.0

func dash_multiplier() -> float:
	return powerups.haste.dash_multiplier if timers.haste > 0.0 else 1.0

func melee_multiplier(weapon_id: String) -> float:
	if timers.berserk <= 0.0:
		return 1.0
	return powerups.berserk.damage_multiplier if weapon_id == "quick_melee" else 2.2

func damage_after_shield(amount: int) -> int:
	if timers.shield <= 0.0:
		return amount
	return max(1, int(amount * powerups.shield.shield_multiplier))

func is_active(id: String) -> bool:
	return timers.get(id, 0.0) > 0.0
