extends "res://scripts/battle.gd"
## Production adapter: retains story/outcome/equipment/HP/qi interfaces of Battle.
var grid
var grid_ui: Control
var board
var status_cards: Array=[]
var utility_buttons: Array=[]
var phase_label: Label
var clock_label: Label
var field_label: Label
var choice="move"
var facing=Vector2i.RIGHT
var awaiting_player=false
var animation_time=.48
var opponent_side=1.0
func _ready() -> void:
 super._ready()
 # Retain legacy widgets for old save fields, but render only the new grid HUD.
 for child in get_children():
  if child!=scene_image and child!=player_actor and child!=enemy_actor:child.hide()
 board=preload("res://scripts/grid_battle_board.gd").new();board.battle=self;board.size=Vector2(1280,720);add_child(board);move_child(board,1)
 preload("res://scripts/grid_battle_hud.gd").build(self)
 move_child(damage_label,get_child_count()-1)
func begin(inner_power: int=-1) -> void:
 awaiting_player=false;grid=null
 super.begin(inner_power)
 var backdrop=encounter.get("premium_background",encounter.get("background_texture","res://assets/battle/premium/river-deck.png" if encounter.is_empty() else "res://assets/battle/premium/bamboo-court.png"))
 if backdrop=="res://assets/battle/deck-empty.png":backdrop="res://assets/battle/premium/river-deck.png"
 if backdrop=="res://assets/battle/road-empty.png":backdrop="res://assets/battle/premium/bamboo-court.png"
 scene_image.texture=load(backdrop);scene_image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 grid=preload("res://scripts/grid_combat.gd").new()
 grid.combat=combat
 grid.setup(encounter.get("field",{}),{"stats":player_stats.duplicate(),"weapon":equipped_weapon_id,"hp":player_hp,"max_hp":Rules.PLAYER_MAX_HP,"skills":loadout.filter(func(id):return id!="")}, {"stats":enemy_stats.duplicate(),"weapon":enemy_weapon,"hp":enemy_hp,"max_hp":enemy_max_hp,"skills":enemy_skills.duplicate(),"ai":encounter.get("ai",tutorial_enemy.ai if encounter.is_empty() else {"style":"adaptive"}).duplicate()})
 _update_status_portrait()
 choice="move";facing=Vector2i.RIGHT;opponent_side=1.0;grid_ui.show();board.show();player_actor.scale=Vector2.ONE*.25;enemy_actor.scale=Vector2.ONE*.31
 _place_actors();refresh_grid();_start_grid.call_deferred(generation)
func _start_grid(token: int) -> void:
 if token!=generation or not running:return
 # Old mid-combat saves have HP/qi restored immediately after begin; retain those values.
 grid.units[0].hp=player_hp;grid.units[1].hp=enemy_hp;grid.units[0].qi=qi.amount;grid.units[1].qi=enemy_qi.amount
 grid.units[0].actions=maxi(0,turn-1);grid.units[0].ready=ready_turns.duplicate();grid.units[1].ready=enemy_ready_turns.duplicate()
 _drive(token)
func _drive(token: int) -> void:
 while token==generation and running:
  var actor=grid.next_actor();refresh_grid()
  if actor<0:return
  if actor==0:
   awaiting_player=true;busy=false;refresh_grid();return
  awaiting_player=false;busy=true;phase_label.text="對陣 · 상대의 차례";refresh_grid()
  await get_tree().create_timer(maxf(.02,animation_time),false).timeout
  if token!=generation or not running:return
  var action=grid.enemy_choice()
  var event=grid.perform(1,action.id,action.facing,action.get("destination",Vector2i(-1,-1)))
  if not event.ok:push_error("GRID enemy stalled: "+event.reason);return
  await _present(event,token)
func cancel() -> void:
 awaiting_player=false
 super.cancel()
func _update_intent() -> void:
 if is_instance_valid(intent_label):intent_label.text="";intent_label.hide()
func select_slot(index: int) -> void:
 if index>=0 and index<loadout.size() and loadout[index]!="":select_skill(str(loadout[index]))
func select_skill(id: String) -> void:
 if not running or busy:return
 if id not in loadout and id!="basic_attack":return
 if martial_arts.get_skill(id).is_empty():return
 selected_action=id;selected=true;choice=id;refresh_grid()
func use_selected() -> void:
 if not running:
  if player_hp==0 and encounter.is_empty():begin()
  return
 if grid==null or not awaiting_player or busy:return
 if choice=="move":note.text="청록색 자리나 WASD로 한 걸음 이동하세요.";return
 commit(choice)
func commit(id: String,destination: Vector2i=Vector2i(-1,-1)) -> void:
 if not awaiting_player or busy or not running:return
 var event=grid.perform(0,id,facing,destination)
 if not event.ok:note.text=event.reason;return
 awaiting_player=false;busy=true
 var token=generation
 await _present(event,token)
 if token==generation and running:_drive(token)
func click_cell(point: Vector2i) -> void:
 if not awaiting_player or busy:return
 if choice=="move":commit("move",point)
 elif point in grid.footprint(0,choice,facing).attacks:commit(choice)
func utility(index: int) -> void:
 if busy or not running:return
 match index:
  0:choice="move";selected=false;selected_action=""
  1:facing=grid.DIRECTIONS[(grid.DIRECTIONS.find(facing)+1)%4]
  2:select_skill("basic_attack")
  3:choice="wait";selected=false;selected_action=""
 refresh_grid()
func _input(event: InputEvent) -> void:
 if not visible or not running or busy or not awaiting_player or not event.is_pressed() or event.is_echo():return
 # Menus/help may consume input first; paused gameplay never executes a battle action.
 if get_tree().paused:return
 var code=event.physical_keycode if event.physical_keycode!=0 else event.keycode
 var directions={KEY_W:Vector2i.UP,KEY_UP:Vector2i.UP,KEY_S:Vector2i.DOWN,KEY_DOWN:Vector2i.DOWN,KEY_A:Vector2i.LEFT,KEY_LEFT:Vector2i.LEFT,KEY_D:Vector2i.RIGHT,KEY_RIGHT:Vector2i.RIGHT}
 if code in directions:facing=directions[code];choice="move";selected=false;selected_action="";commit("move",grid.units[0].position+facing);get_viewport().set_input_as_handled()
 elif code==KEY_B:utility(2);get_viewport().set_input_as_handled()
 elif code==KEY_G:utility(3);get_viewport().set_input_as_handled()
 elif code==KEY_R:utility(1);get_viewport().set_input_as_handled()
 elif code in [KEY_1,KEY_2,KEY_3,KEY_4]:select_slot(code-KEY_1);get_viewport().set_input_as_handled()
 elif code==KEY_ENTER or code==KEY_SPACE:use_selected();get_viewport().set_input_as_handled()
func _place_actors() -> void:
 if grid==null:return
 for index in range(2):
  var actor=player_actor if index==0 else enemy_actor
  actor.home=board.foot(grid.units[index].position);actor.reset_motion()
func _present(event: Dictionary,token: int) -> void:
 if token!=generation:return
 var actor=player_actor if event.actor==0 else enemy_actor
 var victim=enemy_actor if event.actor==0 else player_actor
 var name="도원" if event.actor==0 else enemy_name.text
 var label={"move":"이동","wait":"숨 고르기"}.get(event.id,combat.arts.get_skill(event.id).get("name",event.id))
 var unit=grid.units[event.actor]
 player_hp=grid.units[0].hp;enemy_hp=grid.units[1].hp;enemy_guard=grid.units[1].guard
 ready_turns=grid.units[0].ready.duplicate();enemy_ready_turns=grid.units[1].ready.duplicate()
 turn=1+grid.units[0].actions
 qi.restore(int(player_stats.inner),grid.units[0].qi);enemy_qi.restore(int(enemy_stats.inner),grid.units[1].qi)
 var moving=event.id=="move" or event.before!=unit.position
 var attack=float(combat.action(event.id,unit.stats,unit.weapon).get("raw",0))>0
 if attack:_basic_fx("attack",actor.home+Vector2(unit.facing)*34+Vector2(0,-30),Vector2(unit.facing))
 elif event.id not in ["move","wait"]:_basic_fx("guard",actor.home+Vector2(0,-35),Vector2(unit.facing))
 if moving:
  actor.walker=preload("res://scripts/battle_step.gd").new();actor.add_child(actor.walker);actor.walker.configure(actor,animation_time)
  actor.home=board.foot(unit.position);actor.motion=actor.create_tween();actor.motion.tween_property(actor,"position",actor.home,animation_time*.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  _basic_fx("step",board.foot(event.before),Vector2(unit.facing))
  if attack:actor.motion.tween_callback(actor.set_pose.bind("strike"));sound_requested.emit("attack_"+actor.weapon_type)
 elif attack:
  actor.set_pose("windup");sound_requested.emit("attack_"+actor.weapon_type)
  var tween=actor.create_tween();actor.motion=tween;tween.tween_property(actor,"position",actor.home+Vector2(unit.facing)*18,animation_time*.4)
  tween.tween_callback(actor.set_pose.bind("strike"));tween.tween_property(actor,"position",actor.home,animation_time*.4)
 else:actor.defend(animation_time)
 if event.damage>0:
  victim.hurt();sound_requested.emit("hit");_basic_fx("hit",victim.home+Vector2(0,-32),Vector2(unit.facing))
 elif event.id not in ["move","wait"]:sound_requested.emit("block")
 log_action(name,str(label),event.damage,event.qi_cost,event.guard_used,unit.qi)
 refresh_grid(true)
 if event.damage>0:
  damage_label.position=Vector2(victim.home.x-25,maxf(194,victim.home.y-106));damage_label.text="−%d" % event.damage;damage_label.modulate.a=1;damage_label.show()
  var floating=create_tween().set_parallel();float_tween=floating;floating.tween_property(damage_label,"position:y",damage_label.position.y-25,maxf(.1,animation_time));floating.tween_property(damage_label,"modulate:a",0,maxf(.1,animation_time))
 note.text=name+" · "+str(label)+(" · 피해 %d" % event.damage if event.damage>0 else "")
 await get_tree().create_timer(maxf(.02,animation_time),false).timeout
 if token!=generation or not running:return
 _place_actors();damage_label.hide()
 if grid.winner>=0:
  running=false;busy=false;awaiting_player=false
  if grid.winner==0:victory.emit(player_hp)
  else:
   defeat.emit()
   if encounter.is_empty():heading.text="교전에서 밀려났습니다";use_button.text="다시 도전";use_button.disabled=false
func refresh_grid(animate: bool=false) -> void:
 if grid==null or not is_instance_valid(grid_ui):return
 var factor=minf(1.0,minf(board.cell_size().y/60.0,board.cell_size().x/100.0))
 _face_opponent(factor)
 for index in range(2):
  var unit=grid.units[index];var card=status_cards[index];var stats=unit.stats
  card.hp.text="체력 %d / %d" % [unit.hp,unit.max_hp];card.bar.set_health(unit.hp,unit.max_hp,animate)
  card.qi.text="내기 %d / 500  · 행동 후 +%d" % [unit.qi,int(stats.inner)]
  card.gauge_bar.value=unit.gauge
  card.gauge.text="행동력 %d  · 충전 +%d / 박" % [unit.gauge,int(stats.agility)+grid.SPEED_BASE]
  card.weapon.text=str(weapons.get_weapon(unit.weapon).get("name","맨손"))+(" · 방어 %d%%" % unit.guard if unit.guard>0 else "")
  card.stats.text="근력 %d   기민 %d   근골 %d   내공 %d   오성 %d" % [stats.strength,stats.agility,stats.constitution,stats.inner,stats.insight]
  card.gauge.tooltip_text=card.stats.text
 status_cards[1].name.text=str(encounter.get("name","흑린채 수적"))
 status_cards[1].name.tooltip_text=str(encounter.get("faction","흑린채 · 일반 수적"))
 phase_label.text="도원의 차례" if awaiting_player else "상대의 차례"
 clock_label.text="행동력 100 이상에서 출수 · 충전 %d박" % grid.tick
 field_label.text="%d × %d  ·  %s" % [grid.field.width,grid.field.height,{Vector2i.RIGHT:"동쪽 →",Vector2i.DOWN:"남쪽 ↓",Vector2i.LEFT:"서쪽 ←",Vector2i.UP:"북쪽 ↑"}.get(facing,"")]
 var id=choice
 heading.text={"move":"보법 · 한 걸음 이동","wait":"숨 고르기"}.get(id,martial_arts.get_skill(id).get("name","초식 선택"))
 var cost=grid.cost(id);var action=combat.action(id,player_stats,equipped_weapon_id)
 metrics.text="행동력 %d · 내기 %d%s" % [cost,int(action.get("cost",0))," · 위력 %s" % str(snappedf(float(action.raw),.01)) if action.get("raw",0)>0 else ""]
 detail.text="청록색 자리 클릭 또는 WASD · 이동도 한 행동입니다." if id=="move" else "행동력20으로 호흡을 가다듬고 내기를 회복합니다." if id=="wait" else grid.tactics.get_tactics(id).description
 var problem="상대의 행동을 기다리세요." if not awaiting_player else grid.problem(0,id,facing) if id!="move" else ""
 note.text=problem if not problem.is_empty() else "주홍색 범위를 확인하고 출수하세요." if id!="move" else "방향 전환은 R · 기본공격은 별도 선택 가능"
 use_button.disabled=busy or not awaiting_player or not problem.is_empty() or id=="move"
 for index in range(4):
  var skill=str(loadout[index]);var button=skill_buttons[index]
  button.text="비어 있는 초식" if skill=="" else str(martial_arts.get_skill(skill).name)
  Icons.apply(button,skill,30);button.disabled=busy or skill=="";preload("res://scripts/battle_art_skin.gd").selection(button,choice==skill and skill!="")
 for button in utility_buttons:
  button.disabled=busy;preload("res://scripts/battle_art_skin.gd").selection(button,choice=="move")
 board.queue_redraw()
func _update_slots() -> void:
 if grid==null:super._update_slots()
 else:refresh_grid()
func _update_hp(animate: bool=false) -> void:
 if grid==null:super._update_hp(animate)
 else:refresh_grid(animate)
func _refresh_availability() -> void:
 if grid!=null and running:refresh_grid()

func _basic_fx(kind: String,point: Vector2,direction: Vector2) -> void:
 var effect=preload("res://scripts/battle_basic_fx.gd").new();effect.kind=kind;effect.position=point;effect.direction=direction;effect.token=generation
 add_child(effect);move_child(effect,grid_ui.get_index())

func _update_status_portrait() -> void:
 var portraits=preload("res://scripts/dialogue_portraits.gd")
 var id=str(encounter.get("portrait_actor",encounter.get("id","pirate")))
 id={"bandit_sentry":"bandit_raider","bandit_ringleader":"bandit_leader","qingya_chief":"bandit_raider","herb_ruffian":"bandit_raider"}.get(id,id)
 var actor=portraits.ACTORS.get(id,portraits.ACTORS["bandit_raider"] if str(encounter.get("name","")).contains("산적") else portraits.ACTORS["recipient"])
 var resolver=portraits.new();var texture=resolver.texture_for(actor);resolver.free()
 var atlas=AtlasTexture.new();atlas.atlas=texture;atlas.region=Rect2(0,0,texture.get_width(),texture.get_height()*.64)
 status_cards[1].portrait.texture=atlas

func _exit_tree() -> void:
 preload("res://scripts/battle_art_skin.gd").sources.clear()

func _process(_delta: float) -> void:
 if grid!=null and running and is_visible_in_tree():
  _face_opponent(minf(1.0,minf(board.cell_size().y/60.0,board.cell_size().x/100.0)))

func _face_opponent(factor: float) -> void:
 # Art orientation is independent of the selected skill direction. Compare animated
 # feet so crossing during a step flips at the crossing, not at the committed end cell.
 if grid.units[0].position.x!=grid.units[1].position.x:
  var difference=enemy_actor.position.x-player_actor.position.x
  if absf(difference)>.5:opponent_side=signf(difference)
 # Same column: retain the last horizontal relationship, including hit recoil.
 # Hero artwork faces right by default; enemy artwork faces left by default.
 player_actor.scale=Vector2(.25*opponent_side,.25)*factor
 enemy_actor.scale=Vector2(.31*opponent_side,.31)*factor
