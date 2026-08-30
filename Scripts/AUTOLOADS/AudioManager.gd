extends Node

const SFX_POOL_SIZE := 8
const MIN_VOLUME_DB := -80.0

var _sfx_pool: Array[AudioStreamPlayer] = []
var _steal_index := 0

var _music_player: AudioStreamPlayer
var _music_tween: Tween
var _stopping := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in SFX_POOL_SIZE:
		_sfx_pool.append(_make_player(&"SFX"))

	_music_player = _make_player(&"Music")

	apply_volumes()


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return

	var player := _get_free_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func play_sfx_at(stream: AudioStream, world_position: Vector2, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return

	var scene := get_tree().current_scene
	if scene == null:
		play_sfx(stream, volume_db, pitch_scale)
		return

	var player := AudioStreamPlayer2D.new()
	player.bus = &"SFX"
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = 4000.0
	player.panning_strength = 2.0
	player.finished.connect(player.queue_free)
	scene.add_child(player)
	player.global_position = world_position
	player.play()


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player

	_steal_index = (_steal_index + 1) % _sfx_pool.size()
	return _sfx_pool[_steal_index]


func play_music(stream: AudioStream, fade_in: float = 0.0) -> void:
	if stream == null:
		return
	if _music_player.stream == stream and _music_player.playing and not _stopping:
		return
	_stopping = false

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
		_stopping = false
		_music_player.stop()
		_music_player.volume_db = 0.0
		return

	_stopping = true

	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", MIN_VOLUME_DB, fade_out)
	_music_tween.tween_callback(_music_player.stop)
	_music_tween.tween_callback(func():
		_stopping = false
		_music_player.volume_db = 0.0)


func set_sfx_volume(percent: float) -> void:
	Global.sfx_volume = percent
	apply_volumes()


func set_music_volume(percent: float) -> void:
	Global.music_volume = percent
	apply_volumes()

func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _percent_to_db(Global.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _percent_to_db(Global.music_volume))

																				
func _percent_to_db(percent: float) -> float:
	if percent <= 0.0:
		return MIN_VOLUME_DB
	return linear_to_db(clamp(percent / 100.0, 0.0, 1.0))
