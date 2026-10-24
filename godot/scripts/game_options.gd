extends Node
## Device preferences are separate from story saves and survive returning to title.
const FILE="user://preferences.cfg"
const SFX={"attack_sword":preload("res://assets/sfx/attack_sword.wav"),"attack_saber":preload("res://assets/sfx/attack_saber.wav"),"attack_spear":preload("res://assets/sfx/attack_spear.wav"),"attack_none":preload("res://assets/sfx/attack_none.wav"),"confirm":preload("res://assets/sfx/confirm.wav"),"coin":preload("res://assets/sfx/coin.wav"),"quest":preload("res://assets/sfx/quest.wav"),"learn":preload("res://assets/sfx/learn.wav"),"hit":preload("res://assets/sfx/hit.wav"),"block":preload("res://assets/sfx/block.wav")}
var game
var bgm_volume:=70.0
var sfx_volume:=65.0
var body_size:=21
var fullscreen:=false
var seen: Array=[]
var voices: Array[AudioStreamPlayer]=[]
var next_voice:=0
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	for bus in ["Music","Effects"]:
		if AudioServer.get_bus_index(bus)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	game.music.process_mode=Node.PROCESS_MODE_ALWAYS
	for voice in game.music.players:voice.bus="Music"
	for i in range(6):
		var voice=AudioStreamPlayer.new();voice.bus="Effects";add_child(voice);voices.append(voice)
	var cfg=ConfigFile.new()
	if cfg.load(FILE)==OK:
		bgm_volume=clampf(float(cfg.get_value("audio","bgm",70)),0,100);sfx_volume=clampf(float(cfg.get_value("audio","sfx",65)),0,100)
		var requested=int(cfg.get_value("display","body_size",21));body_size=requested if requested in [18,21,24] else 21
		var remembered=cfg.get_value("tutorial","seen",[])
		if remembered is Array:
			for id in remembered:
				if id is String:seen.append(id)
		fullscreen=bool(cfg.get_value("display","fullscreen",false))
	apply()
func apply() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),linear_to_db(maxf(.00001,bgm_volume/100)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),bgm_volume==0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"),linear_to_db(maxf(.00001,sfx_volume/100)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Effects"),sfx_volume==0)
	if DisplayServer.get_name()!="headless":
		var wanted: int=DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode()!=wanted:DisplayServer.window_set_mode(wanted)
	var font_changed: bool=game.dialogue_text.get_theme_font_size("font_size")!=body_size
	game.dialogue_text.add_theme_font_size_override("font_size",body_size)
	var large:=body_size==24
	game.dialogue_panel.position.y=495 if large else 535;game.dialogue_panel.size.y=200 if large else 160
	game.dialogue_text.size.y=123 if large else 83;game.dialogue_cast.size.y=370 if large else 410
	game.dialogue_next.position.y=146 if large else 106
	var participants: Array=[]
	for id in game.dialogue_cast.portraits:
		var actor: Dictionary=game.PORTRAITS.ACTORS[id].duplicate();actor.id=id;participants.append(actor)
	if font_changed and not participants.is_empty() and not game.dialogue_lines.is_empty():
		game.dialogue_cast.set_participants(participants);game._show_line()
	game.dialogue_history.transcript.add_theme_font_size_override("normal_font_size",body_size)
	if is_instance_valid(game.adventure_ui):game.adventure_ui.apply_font()
func update(key: String,value) -> void:
	match key:
		"bgm":bgm_volume=clampf(float(value),0,100)
		"sfx":sfx_volume=clampf(float(value),0,100)
		"size":body_size=[18,21,24][clampi(int(value),0,2)]
		"fullscreen":fullscreen=bool(value)
	apply();persist()
func persist() -> void:
	var cfg=ConfigFile.new();cfg.set_value("audio","bgm",bgm_volume);cfg.set_value("audio","sfx",sfx_volume)
	cfg.set_value("display","body_size",body_size);cfg.set_value("display","fullscreen",fullscreen);cfg.set_value("tutorial","seen",seen);cfg.save(FILE)
func play(id: String) -> void:
	if not SFX.has(id):return
	var voice=voices[next_voice];next_voice=(next_voice+1)%voices.size();voice.stop();voice.stream=SFX[id];voice.play()
