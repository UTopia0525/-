extends SceneTree
var music
var failed:=false
var finished_count:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:failed=true;push_error("MUSIC_LOOP: "+message)
func run() -> void:
	music=load("res://scripts/music.gd").new();root.add_child(music);music.fade_seconds=.05
	for p in music.players:p.finished.connect(func():finished_count+=1)
	for id in music.TRACKS:
		music.play_track(id);await create_timer(.12).timeout
		var active=music.players[music.current_index]
		for cycle in range(2):
			var count_before=finished_count
			active.seek(active.stream.get_length()-.18);await create_timer(.7).timeout
			check(active.playing and active.get_playback_position()<2.0,"real OGG boundary repeats: "+id)
			check(finished_count==count_before,"native repetition stays uninterrupted: "+id)
		# Exercise the failure path with a real EOF, not an emitted fake signal.
		active.stream.loop=false;active.seek(active.stream.get_length()-.18)
		var before=finished_count;var index: int=music.current_index
		await create_timer(.8).timeout
		check(finished_count>before and active.playing and active.stream.loop,"actual EOF recovers and restores native loop: "+id)
		check(music.current_index==index and music.current_track==id and active.get_playback_position()<2.0,"EOF reuses same song/voice without a fade: "+id)
		check(is_equal_approx(active.volume_db,music.volume_db),"recovered music is audible: "+id)
	music.play_track("dock");await create_timer(.12).timeout
	var active=music.players[music.current_index];var index: int=music.current_index
	active.seek(12);await create_timer(.12).timeout
	var position: float=active.get_playback_position();music.play_track("dock")
	check(music.current_index==index and active.get_playback_position()>=position-.05,"same-map song request preserves position")
	music.set_enabled(false);position=active.get_playback_position();await create_timer(.4).timeout
	check(active.stream_paused and absf(active.get_playback_position()-position)<.15,"music-off stays paused")
	music.play_track("dock");check(music.current_index==index and active.stream_paused,"same song while muted never unpauses or switches voice")
	active.stop();await create_timer(.4).timeout;check(not active.playing,"watchdog respects music-off")
	music.set_enabled(true);await create_timer(.15).timeout;check(active.playing and not active.stream_paused,"reenabling recovers a stopped muted song")
	active.stop();await create_timer(.4).timeout;check(active.playing,"silent stop without finished signal recovers")
	active.seek(59.8);paused=true;await create_timer(.7).timeout
	check(active.playing and active.get_playback_position()<2.0,"menu pause does not stop looping music");paused=false
	for id in ["voyage","dock","battle","ambush","dock"]:music.play_track(id)
	await create_timer(.2).timeout
	check(music.current_track=="dock" and music.players.filter(func(p):return p.playing).size()==1,"rapid context changes leave only current song")
	music._on_voice_finished(1-music.current_index);await process_frame
	check(music.players.filter(func(p):return p.playing).size()==1,"outgoing completion cannot revive an old map song")
	for p in music.players:p.stop();p.stream=null
	music.queue_free();await process_frame
	print("GODOT_MUSIC_LOOP: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
