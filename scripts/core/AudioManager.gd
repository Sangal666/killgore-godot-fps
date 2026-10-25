extends Node
class_name AudioManager

const RATE = 22050
const MAX_SPATIAL_ONE_SHOT_POOL = 24

var bus := "Master"
var muted := false
var master_volume := 0.82
var sfx_volume := 0.78
var music_volume := 0.80
var sfx_players: Array[AudioStreamPlayer] = []
var active_spatial_players: Array[AudioStreamPlayer3D] = []
var spatial_one_shot_pool: Array[AudioStreamPlayer3D] = []
var sfx_volume_boost := {}
var spatial_loops := {}

func _ready() -> void:
	_generate_all()

func _generate_all() -> void:
	_add_sfx("pistol",     _chirp(0.070, 0.30, 520, 170, "square", 0.22))
	_add_sfx("shotgun",    _load_external_sfx("res://assets/audio/shotgunshot2_16.wav", _layered_noise(0.150, 0.58, 32, 125, 0.55)), 8.5)
	_add_sfx("auto",       _chirp(0.043, 0.22, 360, 190, "square", 0.14))
	_add_sfx("plasma",     _chirp(0.105, 0.28, 760, 440, "sine", 0.10))
	_add_sfx("heavy",      _layered_noise(0.180, 0.66, 24, 82, 0.72))
	_add_sfx("railgun",    _chirp(0.150, 0.34, 980, 280, "saw", 0.16))
	_add_sfx("incinerator", _layered_noise(0.120, 0.34, 86, 240, 0.36))
	_add_sfx("saw",        _chirp(0.120, 0.26, 310, 720, "saw", 0.24))
	_add_sfx("cryo",       _chirp(0.135, 0.22, 880, 360, "sine", 0.08))
	_add_sfx("bow",        _chirp(0.075, 0.16, 220, 90, "sine", 0.18))
	_add_sfx("toxic",      _layered_noise(0.090, 0.20, 120, 420, 0.30))
	_add_sfx("grenade_launcher", _layered_noise(0.140, 0.50, 44, 132, 0.58))
	_add_sfx("shock_flux", _chirp(0.105, 0.22, 1120, 480, "saw", 0.24))
	_add_sfx("flak",       _layered_noise(0.120, 0.46, 60, 210, 0.62))
	_add_sfx("melee",      _chirp(0.070, 0.18, 190, 90, "sine", 0.34))
	_add_sfx("whip",       _chirp(0.180, 0.30, 920, 180, "saw", 0.20))
	_add_sfx("explosion",  _layered_noise(0.430, 0.68, 18, 74, 0.86))
	_add_sfx("grenade",    _layered_noise(0.160, 0.42, 52, 118, 0.64))
	_add_sfx("pickup",     _chirp(0.120, 0.24, 740, 1120, "sine", 0.04))
	_add_sfx("health",     _load_external_sfx("res://assets/audio/health_16.wav", _chirp(0.150, 0.24, 520, 1040, "sine", 0.03)), 3.5)
	_add_sfx("player_damage", _load_external_sfx("res://assets/audio/player_damage_16.wav", _layered_noise(0.110, 0.34, 44, 180, 0.62)), 8.8)
	_add_sfx("spider_seek_loop", _load_external_sfx("res://assets/audio/spider_seek_loop_16.wav", _chirp(0.520, 0.18, 120, 360, "sine", 0.16), true), 12.0)
	_add_sfx("powerup",    _chirp(0.190, 0.30, 420, 880, "saw", 0.08))
	_add_sfx("key_materialized", _chirp(0.420, 0.20, 880, 1560, "sine", 0.03))
	_add_sfx("door",       _chirp(0.170, 0.22, 96, 58, "square", 0.24))
	_add_sfx("hit",        _layered_noise(0.060, 0.18, 72, 160, 0.48))
	_add_sfx("empty",      _tone(0.050, 0.18, 55, "square"))
	_add_sfx("dash",       _chirp(0.115, 0.20, 210, 420, "sine", 0.10))
	_add_sfx("slide",      _layered_noise(0.180, 0.24, 72, 210, 0.42))
	_add_sfx("glide",      _layered_noise(0.160, 0.18, 120, 280, 0.22))
	_add_sfx("land",       _layered_noise(0.075, 0.18, 54, 120, 0.36))
	_add_sfx("land_hard",  _layered_noise(0.135, 0.34, 36, 96, 0.56))
	_add_sfx("jump",       _chirp(0.085, 0.052, 155, 230, "sine", 0.08))
	_add_sfx("grapple",    _chirp(0.150, 0.24, 260, 760, "saw", 0.16))
	_add_sfx("enemy_shoot", _chirp(0.085, 0.22, 260, 460, "square", 0.14))

func _add_sfx(name: String, stream: AudioStream, volume_boost_db: float = 0.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.name = name
	player.stream = stream
	player.bus = bus
	player.set_meta("sfx_name", name)
	sfx_volume_boost[name] = volume_boost_db
	player.volume_db = _volume_db() + volume_boost_db
	add_child(player)
	sfx_players.append(player)

func play(sfx: String, pitch_rand: float = 0.0) -> void:
	if muted:
		return
	for child in get_children():
		if child is AudioStreamPlayer and child.name == sfx:
			var p := child as AudioStreamPlayer
			if p.playing:
				p.stop()
			if pitch_rand > 0.0:
				p.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand)
			else:
				p.pitch_scale = 1.0
			p.play()
			return

func stop(sfx: String) -> void:
	for child in get_children():
		if child.get_meta("sfx_name", child.name) != sfx:
			continue
		if child is AudioStreamPlayer:
			var p2d := child as AudioStreamPlayer
			if p2d.playing:
				p2d.stop()
		elif child is AudioStreamPlayer3D:
			var p := child as AudioStreamPlayer3D
			if p.playing:
				p.stop()
	var spatial_index := 0
	while spatial_index < active_spatial_players.size():
		var p = active_spatial_players[spatial_index]
		if not is_instance_valid(p):
			active_spatial_players.remove_at(spatial_index)
			continue
		if p.get_meta("sfx_name", p.name) == sfx:
			if p.playing:
				p.stop()
			if bool(p.get_meta("pooled_spatial_one_shot", false)):
				_recycle_spatial_one_shot(p)
			else:
				p.queue_free()
				active_spatial_players.remove_at(spatial_index)
			continue
		spatial_index += 1

func play_at(sfx: String, pos: Vector3, pitch_rand: float = 0.0) -> void:
	if muted:
		return
	var source := _stream_for_sfx(sfx)
	if source == null:
		return
	var p := _acquire_spatial_one_shot()
	p.name = "%s_spatial" % sfx
	p.set_meta("sfx_name", sfx)
	p.stream = source
	p.bus = bus
	p.global_position = pos
	p.volume_db = _volume_db() + float(sfx_volume_boost.get(sfx, 0.0))
	p.max_distance = 42.0
	p.unit_size = 2.8
	_configure_spatial_sfx_player(p, sfx)
	p.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand) if pitch_rand > 0.0 else 1.0
	p.play()
	active_spatial_players.append(p)

func _acquire_spatial_one_shot() -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D
	if spatial_one_shot_pool.is_empty():
		player = AudioStreamPlayer3D.new()
		player.set_meta("pooled_spatial_one_shot", true)
		player.finished.connect(_recycle_spatial_one_shot.bind(player))
		add_child(player)
	else:
		player = spatial_one_shot_pool.pop_back()
	return player

func _recycle_spatial_one_shot(player: AudioStreamPlayer3D) -> void:
	if not is_instance_valid(player) or not bool(player.get_meta("pooled_spatial_one_shot", false)):
		return
	player.stop()
	active_spatial_players.erase(player)
	player.stream = null
	player.set_meta("sfx_name", "")
	player.pitch_scale = 1.0
	if spatial_one_shot_pool.has(player):
		return
	if spatial_one_shot_pool.size() >= MAX_SPATIAL_ONE_SHOT_POOL:
		player.queue_free()
		return
	spatial_one_shot_pool.append(player)

func play_attached(sfx: String, parent_node: Node3D, local_pos: Vector3 = Vector3.ZERO, pitch_rand: float = 0.0) -> void:
	if muted or not is_instance_valid(parent_node):
		return
	var source := _stream_for_sfx(sfx)
	if source == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.name = "%s_attached" % sfx
	p.set_meta("sfx_name", sfx)
	p.stream = source
	p.bus = bus
	p.position = local_pos
	p.volume_db = _volume_db() + float(sfx_volume_boost.get(sfx, 0.0))
	p.max_distance = 42.0
	p.unit_size = 2.8
	_configure_spatial_sfx_player(p, sfx)
	p.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand) if pitch_rand > 0.0 else 1.0
	parent_node.add_child(p)
	p.play()
	active_spatial_players.append(p)
	p.finished.connect(func():
		active_spatial_players.erase(p)
		p.queue_free()
	)

func play_loop_at(sfx: String, loop_id: String, pos: Vector3, volume_db_offset: float = 0.0) -> void:
	if muted:
		stop_loop(loop_id)
		return
	if sfx == "spider_seek_loop":
		_play_distance_loop_2d(sfx, loop_id, volume_db_offset)
		return
	var p: AudioStreamPlayer3D = spatial_loops.get(loop_id, null)
	if p != null and is_instance_valid(p):
		p.global_position = pos
		p.volume_db = _volume_db() + float(sfx_volume_boost.get(sfx, 0.0)) + volume_db_offset
		if not p.playing:
			p.play()
		return
	var source := _stream_for_sfx(sfx)
	if source == null:
		return
	p = AudioStreamPlayer3D.new()
	p.name = "%s_loop" % sfx
	p.set_meta("sfx_name", sfx)
	p.stream = source
	p.bus = bus
	p.global_position = pos
	p.volume_db = _volume_db() + float(sfx_volume_boost.get(sfx, 0.0)) + volume_db_offset
	p.max_distance = 58.0
	p.unit_size = 6.0
	_configure_spatial_sfx_player(p, sfx)
	add_child(p)
	p.play()
	active_spatial_players.append(p)
	spatial_loops[loop_id] = p

func _play_distance_loop_2d(sfx: String, loop_id: String, volume_db_offset: float = 0.0) -> void:
	var p: AudioStreamPlayer = spatial_loops.get(loop_id, null)
	if p != null and is_instance_valid(p):
		p.volume_db = _volume_db() + float(sfx_volume_boost.get(sfx, 0.0)) + volume_db_offset
		if not p.playing:
			p.play()
		return
	var source := _stream_for_sfx(sfx)
	if source == null:
		return
	p = AudioStreamPlayer.new()
	p.name = "%s_loop" % sfx
	p.set_meta("sfx_name", sfx)
	p.stream = source
	p.bus = bus
	p.volume_db = _volume_db() + float(sfx_volume_boost.get(sfx, 0.0)) + volume_db_offset
	add_child(p)
	p.play()
	spatial_loops[loop_id] = p

func stop_loop(loop_id: String) -> void:
	var p = spatial_loops.get(loop_id, null)
	if p != null and is_instance_valid(p):
		if p.playing:
			p.stop()
		if p is AudioStreamPlayer3D:
			active_spatial_players.erase(p)
		p.queue_free()
	spatial_loops.erase(loop_id)

func _configure_spatial_sfx_player(player: AudioStreamPlayer3D, sfx: String) -> void:
	player.area_mask = 0
	player.attenuation_filter_cutoff_hz = 20500.0
	player.attenuation_filter_db = 0.0
	if sfx == "shotgun":
		player.emission_angle_enabled = false
		player.max_db = 8.0
	if sfx == "spider_seek_loop":
		player.max_distance = 96.0
		player.unit_size = 14.0
		player.max_db = 8.0

func _stream_for_sfx(sfx: String) -> AudioStream:
	for child in get_children():
		if child is AudioStreamPlayer and child.name == sfx:
			return (child as AudioStreamPlayer).stream
	return null

func _load_external_sfx(path: String, fallback: AudioStream, loop: bool = false) -> AudioStream:
	var wav := AudioStreamWAV.load_from_file(path)
	if wav != null:
		_prepare_loaded_wav(wav, loop)
		return wav
	wav = _load_raw_pcm_wav(path, loop)
	if wav != null:
		return wav
	if path.begins_with("res://"):
		var absolute_path = ProjectSettings.globalize_path(path)
		wav = AudioStreamWAV.load_from_file(absolute_path)
		if wav != null:
			_prepare_loaded_wav(wav, loop)
			return wav
		wav = _load_raw_pcm_wav(absolute_path, loop)
		if wav != null:
			return wav
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStream:
			if loop and stream is AudioStreamWAV:
				_prepare_loaded_wav(stream, loop)
			return stream
	if loop and fallback is AudioStreamWAV:
		_prepare_loaded_wav(fallback, loop)
	return fallback

func _prepare_loaded_wav(wav: AudioStreamWAV, loop: bool) -> void:
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = _wav_frame_count(wav)

func _wav_frame_count(wav: AudioStreamWAV) -> int:
	var channels = 2 if wav.stereo else 1
	var bytes_per_sample = 2
	match wav.format:
		AudioStreamWAV.FORMAT_8_BITS:
			bytes_per_sample = 1
		AudioStreamWAV.FORMAT_16_BITS:
			bytes_per_sample = 2
		_:
			bytes_per_sample = 2
	return max(1, int(wav.data.size() / max(1, channels * bytes_per_sample)))

func _load_raw_pcm_wav(path: String, loop: bool) -> AudioStreamWAV:
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 44:
		return null
	if _wav_fourcc(bytes, 0) != "RIFF" or _wav_fourcc(bytes, 8) != "WAVE":
		return null
	var channels = 1
	var sample_rate = RATE
	var bits_per_sample = 16
	var audio_format = 1
	var data := PackedByteArray()
	var offset = 12
	while offset + 8 <= bytes.size():
		var chunk_id = _wav_fourcc(bytes, offset)
		var chunk_size = _wav_u32(bytes, offset + 4)
		var chunk_start = offset + 8
		if chunk_start + chunk_size > bytes.size():
			break
		if chunk_id == "fmt ":
			audio_format = _wav_u16(bytes, chunk_start)
			channels = _wav_u16(bytes, chunk_start + 2)
			sample_rate = _wav_u32(bytes, chunk_start + 4)
			bits_per_sample = _wav_u16(bytes, chunk_start + 14)
		elif chunk_id == "data":
			data = bytes.slice(chunk_start, chunk_start + chunk_size)
		offset = chunk_start + chunk_size + int(chunk_size % 2)
	if audio_format != 1 or data.is_empty():
		return null
	var wav := AudioStreamWAV.new()
	match bits_per_sample:
		8:
			wav.format = AudioStreamWAV.FORMAT_8_BITS
		16:
			wav.format = AudioStreamWAV.FORMAT_16_BITS
		_:
			return null
	wav.mix_rate = sample_rate
	wav.stereo = channels > 1
	wav.data = data
	_prepare_loaded_wav(wav, loop)
	return wav

func _wav_fourcc(bytes: PackedByteArray, offset: int) -> String:
	if offset + 4 > bytes.size():
		return ""
	return "%c%c%c%c" % [bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3]]

func _wav_u16(bytes: PackedByteArray, offset: int) -> int:
	if offset + 2 > bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)

func _wav_u32(bytes: PackedByteArray, offset: int) -> int:
	if offset + 4 > bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)

func toggle_mute() -> void:
	muted = not muted

func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	_apply_volume()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_volume()

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)

func _apply_volume() -> void:
	for p in sfx_players:
		if is_instance_valid(p):
			p.volume_db = _volume_db() + float(sfx_volume_boost.get(p.name, 0.0))
	for p in spatial_loops.values():
		if is_instance_valid(p):
			var sfx_name = p.get_meta("sfx_name", p.name)
			p.volume_db = _volume_db() + float(sfx_volume_boost.get(sfx_name, 0.0))

func _volume_db() -> float:
	var linear = clamp(master_volume * sfx_volume, 0.0, 1.0)
	return -80.0 if linear <= 0.001 else linear_to_db(linear)

func _noise(duration: float, volume: float, _freq_low: float, _freq_high: float) -> AudioStreamWAV:
	var sample_count: int = int(RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)
	var env_scale: float = 1.0 / float(max(1, sample_count))
	var held: float = 0.0
	var hold_samples: int = max(1, int(RATE / max(1.0, _freq_high)))
	for i in sample_count:
		var envelope: float = 1.0 - float(i) * env_scale
		if i % hold_samples == 0:
			held = randf_range(-1.0, 1.0)
		var rumble: float = sin(float(i) / float(RATE) * TAU * _freq_low) * 0.35
		var val: float = (held * 0.72 + rumble) * volume * envelope
		_write_sample(data, i, val)
	return _make_wav(data, RATE)

func _layered_noise(duration: float, volume: float, low: float, high: float, punch: float) -> AudioStreamWAV:
	var sample_count: int = int(RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)
	var held: float = 0.0
	var hold_samples: int = max(1, int(RATE / max(1.0, high)))
	for i in sample_count:
		var t: float = float(i) / float(RATE)
		var n: float = float(i) / float(max(1, sample_count))
		if i % hold_samples == 0:
			held = randf_range(-1.0, 1.0)
		var body: float = sin(t * TAU * low) * (1.0 - n)
		var snap: float = held * pow(1.0 - n, 2.2)
		var tail: float = randf_range(-1.0, 1.0) * 0.28 * (1.0 - n)
		var attack: float = 1.0 if n < 0.08 else 1.0 - punch * min(1.0, (n - 0.08) / 0.92)
		_write_sample(data, i, (body * 0.42 + snap * 0.72 + tail) * volume * attack)
	return _make_wav(data, RATE)

func _tone(duration: float, volume: float, freq: float, wave: String) -> AudioStreamWAV:
	var sample_count: int = int(RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)
	var env_scale: float = 1.0 / float(max(1, sample_count))
	for i in sample_count:
		var t: float = float(i) / float(RATE)
		var envelope: float = 1.0 - float(i) * env_scale
		var phase: float = fmod(t * freq, 1.0)
		var val: float = 0.0
		match wave:
			"sine":
				val = sin(phase * TAU)
			"square":
				val = 1.0 if phase < 0.5 else -1.0
			"saw":
				val = 2.0 * phase - 1.0
		val *= volume * envelope
		_write_sample(data, i, val)
	return _make_wav(data, RATE)

func _chirp(duration: float, volume: float, start_freq: float, end_freq: float, wave: String, noise_mix: float) -> AudioStreamWAV:
	var sample_count: int = int(RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)
	var phase: float = 0.0
	for i in sample_count:
		var n: float = float(i) / float(max(1, sample_count))
		var envelope: float = pow(1.0 - n, 1.7)
		var freq: float = lerp(start_freq, end_freq, n)
		phase = fmod(phase + freq / float(RATE), 1.0)
		var val: float = 0.0
		match wave:
			"sine":
				val = sin(phase * TAU)
			"square":
				val = 1.0 if phase < 0.5 else -1.0
			"saw":
				val = 2.0 * phase - 1.0
		val = val * (1.0 - noise_mix) + randf_range(-1.0, 1.0) * noise_mix
		_write_sample(data, i, val * volume * envelope)
	return _make_wav(data, RATE)

func _write_sample(data: PackedByteArray, index: int, val: float) -> void:
	var s := int(clamp(val * 32767.0, -32768.0, 32767.0))
	var offset := index * 2
	data.encode_s16(offset, s)

func _make_wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.mix_rate = rate
	wav.data = data
	return wav
