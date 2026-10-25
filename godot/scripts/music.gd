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
var watchdog_elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in range(2):
		var player = AudioStreamPlayer.new()
		player.name = "MusicVoice%d" % index
		player.volume_db = -60.0
		add_child(player)
		players.append(player)
		player.finished.connect(_on_voice_finished.bind(index))

func play_track(track_id: String) -> void:
	if not TRACKS.has(track_id):
		push_warning("Unknown music context: " + track_id)
		return
	if current_track == track_id and players[current_index].stream != null:
		_ensure_current_playing()
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
	if value:_ensure_current_playing()

func _on_voice_finished(index: int) -> void:
	# Native OGG looping is the seamless path. If a platform/imported stream
	# nevertheless ends, resume the current song without a new fade-in.
	if index==current_index:_ensure_current_playing.call_deferred()

func _ensure_current_playing() -> void:
	if not enabled or current_track.is_empty() or players.is_empty():return
	var active=players[current_index]
	if active.stream==null or active.playing:return
	if active.stream is AudioStreamOggVorbis:
		active.stream.loop=true
		active.stream.loop_offset=0.0
	active.volume_db=volume_db
	active.play(0.0)
	active.stream_paused=false

func _process(delta: float) -> void:
	watchdog_elapsed+=delta
	if watchdog_elapsed<0.25:return
	watchdog_elapsed=0.0
	# Also recover a stopped voice when no finished signal was delivered. Never
	# revive an outgoing fade voice or override the user's music-off setting.
	_ensure_current_playing()

func toggle() -> void:
	set_enabled(not enabled)
