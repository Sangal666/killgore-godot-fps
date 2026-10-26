extends RefCounted
## Audio responsibility extracted from HorrorSequenceLevel.
## No autonomous ticks or scene ownership; runtime coordinates lifecycle.
## Bare runtime dependencies are explicit parameters; pure helpers need none.

func make_amalgam_breath_loop() -> AudioStreamWAV:
	const MIX_RATE = 16000
	const DURATION = 2.8
	var sample_count = int(MIX_RATE * DURATION)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time = float(index) / float(MIX_RATE)
		var breath = sin(time * TAU * 41.0) * 0.34 + sin(time * TAU * 62.0) * 0.18
		var throat = sin(time * TAU * (25.0 + sin(time * 1.7) * 4.0)) * 0.24
		var pulse = 0.28 + pow(0.5 + 0.5 * sin(time * TAU / DURATION * 2.0), 2.0) * 0.72
		var grain = sin(time * 1193.0) * sin(time * 173.0) * 0.08
		var value = clamp((breath + throat + grain) * pulse * 0.42, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(value * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

func make_monster_reentry_scrape() -> AudioStreamWAV:
	const MIX_RATE = 16000
	const DURATION = 0.92
	var sample_count = int(MIX_RATE * DURATION)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time = float(index) / float(MIX_RATE)
		var phase = time / DURATION
		var attack = smoothstep(0.0, 0.08, phase)
		var release = 1.0 - smoothstep(0.56, 1.0, phase)
		var envelope = attack * release
		var metal = sin(time * TAU * (84.0 + sin(time * 11.0) * 19.0)) * 0.30
		var scrape = sin(time * 1763.0 + sin(time * 57.0) * 3.4) * sin(time * 193.0) * 0.25
		var body = sin(time * TAU * 31.0) * (0.18 + 0.12 * sin(time * 7.0))
		var value = clamp((metal + scrape + body) * envelope * 0.58, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(value * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func make_monster_hunt_inhale() -> AudioStreamWAV:
	const MIX_RATE = 16000
	const DURATION = 0.64
	var sample_count = int(MIX_RATE * DURATION)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time = float(index) / float(MIX_RATE)
		var phase = time / DURATION
		var inhale = smoothstep(0.0, 0.12, phase) * (1.0 - smoothstep(0.62, 1.0, phase))
		var throat = sin(time * TAU * lerp(46.0, 71.0, phase)) * 0.29
		var wet_grain = sin(time * 1789.0 + sin(time * 91.0) * 2.8) * sin(time * 227.0) * 0.15
		var joint_clicks = 0.0
		for click_time in [0.17, 0.31, 0.46]:
			var click_phase = abs(time - click_time)
			if click_phase < 0.018:
				joint_clicks += sin(click_phase * TAU * 1150.0) * (1.0 - click_phase / 0.018) * 0.23
		var value = clamp((throat + wet_grain) * inhale * 0.62 + joint_clicks, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(value * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func make_monster_light_pain_sound() -> AudioStreamWAV:
	const MIX_RATE = 16000
	const DURATION = 0.46
	var sample_count = int(MIX_RATE * DURATION)
	var bytes = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time = float(index) / float(MIX_RATE)
		var phase = time / DURATION
		var envelope = sin(clamp(phase, 0.0, 1.0) * PI) * (1.0 - phase * 0.42)
		var shriek = sin(time * TAU * lerp(310.0, 118.0, phase)) * 0.34
		var throat = sin(time * TAU * (73.0 + sin(time * 34.0) * 18.0)) * 0.38
		var burn_hiss = sin(time * 1987.0) * sin(time * 643.0) * 0.24
		var value = clamp((shriek + throat + burn_hiss) * envelope * 0.72, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(value * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

