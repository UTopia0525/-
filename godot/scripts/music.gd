extends Node

# Original synthesized compositions. No external recordings or runtime downloads.
const TRACKS = {
	"title": preload("res://assets/music/01_dawn_of_jianghu.ogg"),
	"dock": preload("res://assets/music/02_morning_at_the_dock.ogg"),
	"voyage": preload("res://assets/music/03_escort_on_the_water.ogg"),
	"ambush": preload("res://assets/music/04_shadows_in_the_reeds.ogg"),
	"battle": preload("res://assets/music/05_blades_of_the_black_scale.ogg"),
}

@export_range(-40.0, 0.0, 0.5) var volume_db: float = -6.0
@export_range(0.0, 3.0, 0.1) var fade_seconds: float = 0.8
var enabled: bool = true
var current_track: String = ""
var current_index: int = 0
var players: Array[AudioStreamPlayer] = []
var crossfade: Tween
var generation: int = 0

func _ready() -> void:
	for index in range(2):
		var player = AudioStreamPlayer.new()
		player.name = "MusicVoice%d" % index
		player.volume_db = -60.0
		add_child(player)
		players.append(player)

func play_track(track_id: String) -> void:
	if not TRACKS.has(track_id):
		push_warning("Unknown music context: " + track_id)
		return
	if current_track == track_id and players[current_index].playing:
		return
	generation += 1
	if crossfade and crossfade.is_valid():
		crossfade.kill()
	var previous = players[current_index]
	current_index = 1 - current_index
	var next = players[current_index]
	next.stop()
	var stream: AudioStreamOggVorbis = TRACKS[track_id].duplicate()
	stream.loop = true
	stream.loop_offset = 0.0
	next.stream = stream
	next.volume_linear = 0.0
	next.play()
	next.stream_paused = not enabled
	current_track = track_id
	crossfade = create_tween().set_parallel(true)
	crossfade.tween_property(previous, "volume_linear", 0.0, fade_seconds)
	crossfade.tween_property(next, "volume_linear", db_to_linear(volume_db), fade_seconds)
	crossfade.chain().tween_callback(_finish_fade.bind(previous, generation))

func _finish_fade(previous: AudioStreamPlayer, token: int) -> void:
	if token == generation and previous != players[current_index]:
		previous.stop()

func set_enabled(value: bool) -> void:
	enabled = value
	for player in players:
		player.stream_paused = not value

func toggle() -> void:
	set_enabled(not enabled)
