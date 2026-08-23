extends Node
## Central audio system.
## - Pooled AudioStreamPlayers for one-shot / overlapping SFX.
## - A dedicated player for music with optional fade-in.
## - Bus volume control driven by Global.sfx_volume / Global.music_volume.

const SFX_POOL_SIZE := 8
const MIN_VOLUME_DB := -80.0

var _sfx_pool: Array[AudioStreamPlayer] = []
var _steal_index := 0

var _music_player: AudioStreamPlayer
var _music_tween: Tween


func _ready() -> void:
	for i in SFX_POOL_SIZE:
		_sfx_pool.append(_make_player(&"SFX"))

	_music_player = _make_player(&"Music")

	apply_volumes()


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


## Plays a (possibly overlapping) sound effect using a pooled player.
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return

	var player := _get_free_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player

	# All players busy: steal the next one in a round-robin fashion.
	_steal_index = (_steal_index + 1) % _sfx_pool.size()
	return _sfx_pool[_steal_index]


## Starts (or restarts, if different) looping background music.
func play_music(stream: AudioStream, fade_in: float = 0.0) -> void:
	if stream == null:
		return
	if _music_player.stream == stream and _music_player.playing:
		return

	if _music_tween:
		_music_tween.kill()

	_music_player.stream = stream
	_music_player.play()

	if fade_in > 0.0:
		_music_player.volume_db = MIN_VOLUME_DB
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_in)
	else:
		_music_player.volume_db = 0.0


func stop_music(fade_out: float = 0.0) -> void:
	if _music_tween:
		_music_tween.kill()

	if fade_out <= 0.0:
		_music_player.stop()
		return

	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", MIN_VOLUME_DB, fade_out)
	_music_tween.tween_callback(_music_player.stop)


func set_sfx_volume(percent: float) -> void:
	Global.sfx_volume = percent
	apply_volumes()


func set_music_volume(percent: float) -> void:
	Global.music_volume = percent
	apply_volumes()


## Re-applies Global.sfx_volume / Global.music_volume to the audio buses.
func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _percent_to_db(Global.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _percent_to_db(Global.music_volume))


func _percent_to_db(percent: float) -> float:
	if percent <= 0.0:
		return MIN_VOLUME_DB
	return linear_to_db(clamp(percent / 100.0, 0.0, 1.0))
