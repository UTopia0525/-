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
  var button=painter.button(["1  부탁을 맡겠소","2  지금은 어렵겠소"][i],Rect2(590+i*275,126,260,31));button.focus_mode=Control.FOCUS_NONE;button.pressed.connect(choose.bind(i==0));choices.append(button);button.hide()
 painter.free()
var quest_id=""
func setup(host) -> void:
 super.setup(host)
 data.actors.iso_rear_porter.name="창고 짐꾼";PORTRAITS.ACTORS.iso_rear_porter.name="창고 짐꾼"
 data.actors.iso_town_merchant={"name":"약재 행상","basic_portrait":"male_common_b"}
 PORTRAITS.ACTORS.iso_town_merchant=data.actors.iso_town_merchant
 data.conversations.TownMerchant=[["iso_town_merchant","먼 길을 걸으면 몸부터 돌봐야지. 약재가 필요하시오?"],["hero","어떤 약을 다루는지 보겠소."],["iso_town_merchant","웅력환이 있소. 값과 수량을 천천히 살펴보시오."]]
func begin(npc) -> bool:
 if active:return false
 quest_id=errand.quest_for(npc)
 if not super.begin(npc):return false
 if quest_id!="":dialogue_lines=errand.lines_for(quest_id)
 pending="report" if quest_id!="" and errand.phases[quest_id]=="ready" else "trade" if quest_id=="" and str(npc.name)=="TownMerchant" else ""
 dialogue_index=0;_show_line();return true
func _show_line() -> void:
 if target==null:
  dialogue_name.text="도원";dialogue_text.text=dialogue_lines[dialogue_index][1];dialogue_cast.set_speaker("hero");dialogue_next.text="마침  ▸" if dialogue_index==dialogue_lines.size()-1 else "다음  ▸"
 else:super._show_line()
func advance_dialogue() -> void:
 if not active or dialogue_history.visible or choosing:return
 if quest_id!="" and errand.phases[quest_id]=="available" and pending=="" and dialogue_index==dialogue_lines.size()-1:
  choosing=true;dialogue_next.hide()
  if hint!=null:hint.text="1 수락 / 2 사양"
  for button in choices:button.show()
  return
 dialogue_index+=1
 if dialogue_index<dialogue_lines.size():_show_line()
 else:finish()
func choose(accept: bool) -> void:
 if not choosing or dialogue_history.visible:return
 choosing=false
 for button in choices:button.hide()
 dialogue_next.show()
 if hint!=null:hint.text="F  다음 대사"
 pending="accept" if accept else "decline";dialogue_lines=errand.lines_for(quest_id,pending)
 dialogue_index=0;awaiting_release=Input.is_action_pressed("iso_interact");_show_line()
func inspect_quest(id: String) -> bool:
 if active or not errand.has_quest(id) or errand.phases[id]!="active":return false
 quest_id=id;target=null;prior_player_pause=world.actor.motion_paused;world.actor.motion_paused=true;world.actor.stop_motion()
 dialogue_lines=errand.lines_for(id,"inspect");dialogue_index=0;pending="inspect";active=true;awaiting_release=true
 var hero: Dictionary=PORTRAITS.ACTORS.hero.duplicate(true);hero.id="hero";dialogue_cast.set_participants([hero]);show();_show_line();return true
func finish() -> void:
 if not active:return
 var action=pending;var id=quest_id;pending="";quest_id="";choosing=false
 for button in choices:button.hide()
 dialogue_next.show()
 if hint!=null:hint.text="F  다음 대사"
 super.finish();errand.resolve_for(id,action)
func _input(event: InputEvent) -> void:
 if active and choosing and not dialogue_history.visible and event is InputEventKey and event.pressed and not event.echo:
  if event.keycode in [KEY_1,KEY_KP_1]:choose(true);get_viewport().set_input_as_handled();return
  if event.keycode in [KEY_2,KEY_KP_2]:choose(false);get_viewport().set_input_as_handled();return
 super._input(event)
