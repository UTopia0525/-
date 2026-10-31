extends Control
## Prototype host for the actual shared portrait, paper and history components.
## No main.gd instance, quest manager, save system, or global custom actor registration.
const CAST=preload("res://scripts/dialogue_portraits.gd")
var world
var data: Dictionary
# DialogueHistory's small host interface. The prototype has no settings window.
var PORTRAITS: Dictionary
var settings_menu={"window":{"visible":false}}
var dialogue_lines: Array=[]
var dialogue_index=0
var dialogue_panel: Panel
var dialogue_cast
var dialogue_history
var dialogue_name: Label
var dialogue_text: Label
var dialogue_next: Button
var backdrop: ColorRect
var active=false
var target
var awaiting_release=false
var prior_player_pause=false
var prior_target_pause=false
func setup(value) -> void:
	world=value;data=JSON.parse_string(FileAccess.get_file_as_string("res://prototypes/isometric/dialogues.json"));PORTRAITS={"ACTORS":data.actors.duplicate(true)}
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
	backdrop=ColorRect.new();backdrop.color=Color(.025,.045,.04,.64);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(backdrop)
	dialogue_cast=CAST.new();add_child(dialogue_cast)
	dialogue_panel=preload("res://scripts/paper_dialogue_panel.gd").new();dialogue_panel.position=Vector2(49,525);dialogue_panel.size=Vector2(1182,173);dialogue_panel.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(dialogue_panel)
	var painter=preload("res://scripts/paper_menu_base.gd").new();painter.content=dialogue_panel
	painter.box(dialogue_panel,Rect2(37,-14,201,39),painter.TEAL,Color("8d805f"),2)
	dialogue_name=painter.text(dialogue_panel,"",Rect2(51,-11,173,32),25,Color("f3e8d2"),true)
	dialogue_text=painter.text(dialogue_panel,"",Rect2(42,39,1091,81),21,painter.INK);dialogue_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;dialogue_text.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING
	painter.box(dialogue_panel,Rect2(42,117,1090,1),painter.LINE)
	painter.text(dialogue_panel,"F  다음 대사",Rect2(43,129,175,25),15,painter.MUTED)
	var history_button=painter.button("H  지난 대화",Rect2(210,127,166,29));history_button.focus_mode=Control.FOCUS_NONE
	history_button.pressed.connect(func():dialogue_history.open_history())
	dialogue_next=painter.button("다음  ▸",Rect2(1033,126,100,29),true);dialogue_next.focus_mode=Control.FOCUS_NONE;dialogue_next.pressed.connect(advance_dialogue);painter.free()
	dialogue_history=preload("res://scripts/dialogue_history.gd").new();dialogue_history.game=self;add_child(dialogue_history)
	dialogue_history.visibility_changed.connect(_history_visibility_changed)
	hide()
func _history_visibility_changed() -> void:
	# The shared modal consumes key-up events while the host is paused.
	# Reconcile the real key state so the first fresh F after history still works.
	if active and not dialogue_history.visible:awaiting_release=Input.is_action_pressed("iso_interact")
func begin(npc) -> bool:
	if active or not data.conversations.has(str(npc.name)):return false
	target=npc;prior_player_pause=world.actor.motion_paused;prior_target_pause=target.motion_paused
	world.actor.motion_paused=true;target.motion_paused=true;world.actor.stop_motion();target.stop_motion();world.drag=false
	dialogue_lines=data.conversations[str(npc.name)].duplicate(true);dialogue_index=0;active=true;awaiting_release=true
	var participants: Array=[]
	for id in ["hero",dialogue_lines[0][0]]:
		var person: Dictionary=PORTRAITS.ACTORS[id].duplicate(true);person.id=id;participants.append(person)
	dialogue_cast.set_participants(participants);show();_show_line();return true
func _show_line() -> void:
	var line: Array=dialogue_lines[dialogue_index]
	dialogue_name.text=PORTRAITS.ACTORS[line[0]].name;dialogue_text.text=line[1]
	var other=dialogue_lines[0][0]
	dialogue_cast.set_speaker(line[0],{"to":other if line[0]=="hero" else "hero"})
	dialogue_next.text="마침  ▸" if dialogue_index==dialogue_lines.size()-1 else "다음  ▸"
func advance_dialogue() -> void:
	if not active or dialogue_history.visible:return
	dialogue_index+=1
	if dialogue_index<dialogue_lines.size():_show_line()
	else:finish()
func finish() -> void:
	if not active:return
	if dialogue_history.visible:dialogue_history.close_history()
	active=false;dialogue_lines.clear();dialogue_cast.clear();hide()
	world.actor.motion_paused=prior_player_pause;world.actor.input_neutral_required=true
	if is_instance_valid(target):target.motion_paused=prior_target_pause
	target=null;world.interaction.require_release=true;world.interaction.refresh()
func _input(event: InputEvent) -> void:
	if not active:return
	if event is InputEventKey:
		if not dialogue_history.visible:
			if event.is_action_released("iso_interact"):awaiting_release=false
			elif event.pressed and not event.echo:
				if event.keycode==KEY_H:dialogue_history.open_history()
				elif event.is_action_pressed("iso_interact") and not awaiting_release:
					awaiting_release=true;advance_dialogue()
		get_viewport().set_input_as_handled()
func _exit_tree() -> void:
	# Shared history pauses the tree. Never leave that pause behind on scene removal.
	if is_instance_valid(dialogue_history) and dialogue_history.visible and get_tree()!=null:get_tree().paused=dialogue_history.prior_pause
