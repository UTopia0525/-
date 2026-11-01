extends "res://prototypes/isometric/iso_dialogue.gd"
var errand
var pending=""
var choosing=false
var choices: Array[Button]=[]
var hint: Label
func _ready() -> void:
 super._ready()
 for child in dialogue_panel.get_children():
  if child is Label and child.text=="F  다음 대사":hint=child
 var painter=preload("res://scripts/paper_menu_base.gd").new();painter.content=dialogue_panel
 for i in range(2):
  var b=painter.button(["1  부탁을 맡겠소","2  지금은 어렵겠소"][i],Rect2(590+i*275,126,260,31));b.focus_mode=Control.FOCUS_NONE;b.pressed.connect(choose.bind(i==0))
  choices.append(b);b.hide()
 painter.free()
func begin(npc) -> bool:
 if errand==null or str(npc.name)!="GatePorter":return super.begin(npc)
 if not super.begin(npc):return false
 dialogue_lines=errand.lines();dialogue_index=0;pending="report" if errand.phase=="ready" else "";_show_line();return true
func inspect() -> bool:
 if active or errand.phase!="active":return false
 target=null;prior_player_pause=world.actor.motion_paused;world.actor.motion_paused=true;world.actor.stop_motion()
 dialogue_lines=[["hero","대패가 탁자 위에 그대로 있군. 날에도 이가 나간 곳은 없어 보인다."],["hero","함부로 가져갈 물건은 아니지. 그대로 두고, 문길의 짐꾼에게 무사하다고 전하자."]]
 dialogue_index=0;pending="inspect";active=true;awaiting_release=true
 var hero=PORTRAITS.ACTORS.hero.duplicate(true);hero.id="hero";dialogue_cast.set_participants([hero]);show();_show_line();return true
func _show_line() -> void:
 if target==null:
  dialogue_name.text="도원";dialogue_text.text=dialogue_lines[dialogue_index][1];dialogue_cast.set_speaker("hero");dialogue_next.text="마침  ▸" if dialogue_index==dialogue_lines.size()-1 else "다음  ▸"
 else:super._show_line()
func advance_dialogue() -> void:
 if not active or dialogue_history.visible or choosing:return
 if target!=null and str(target.name)=="GatePorter" and errand.phase=="available" and pending=="" and dialogue_index==dialogue_lines.size()-1:
  choosing=true;dialogue_next.hide()
  if hint!=null:hint.text="1 수락 / 2 사양"
  for b in choices:b.show()
  return
 super.advance_dialogue()
func choose(accept: bool) -> void:
 if not choosing or dialogue_history.visible:return
 choosing=false
 for b in choices:b.hide()
 dialogue_next.show()
 if hint!=null:hint.text="F  다음 대사"
 pending="accept" if accept else "decline"
 dialogue_lines=[["iso_gate_porter","고맙소. 아랫골목 담장 없는 민가요. 탁자 위 대패만 확인해 주시오. 가져올 필요는 없소."],["hero","그 자리에 있는지만 살피고 돌아오겠소."]] if accept else [["iso_gate_porter","그럴 수도 있지. 손이 비거든 다시 들러 주시오. 내 짐이 끝나면 나라도 가 봐야겠소."]]
 dialogue_index=0;awaiting_release=Input.is_action_pressed("iso_interact");_show_line()
func finish() -> void:
 var action=pending;pending="";choosing=false
 for b in choices:b.hide()
 dialogue_next.show()
 if hint!=null:hint.text="F  다음 대사"
 super.finish()
 if errand!=null:errand.resolve(action)
func _input(event: InputEvent) -> void:
 if active and choosing and not dialogue_history.visible and event is InputEventKey and event.pressed and not event.echo:
  if event.keycode in [KEY_1,KEY_KP_1]:choose(true);get_viewport().set_input_as_handled();return
  if event.keycode in [KEY_2,KEY_KP_2]:choose(false);get_viewport().set_input_as_handled();return
 super._input(event)
