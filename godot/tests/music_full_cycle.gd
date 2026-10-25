extends SceneTree
var music
func _initialize() -> void:run.call_deferred()
func run() -> void:
	music=load("res://scripts/music.gd").new();root.add_child(music);music.fade_seconds=0
	music.play_track("dock")
	# Wait for the audio clock itself: Dummy-driver mixing can lag wall-clock
	# timers under concurrent test load. Never seek or skip any song samples.
	var active=music.players[music.current_index]
	var deadline=Time.get_ticks_msec()+90000
	var reached_end:=false
	var ok:=false
	while Time.get_ticks_msec()<deadline:
		await create_timer(.1).timeout
		var position: float=active.get_playback_position()
		if position>55.0:reached_end=true
		if reached_end and active.playing and position<5.0:
			ok=music.current_track=="dock";break
	print("GODOT_MUSIC_FULL_CYCLE: "+("PASS" if ok else "FAIL")+" position="+str(active.get_playback_position()))
	for p in music.players:p.stop();p.stream=null
	music.queue_free();await process_frame;quit(0 if ok else 1)
