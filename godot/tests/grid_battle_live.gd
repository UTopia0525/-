extends SceneTree
var b
var failed=false
func check(value: bool,message: String) -> void:
 if not value:failed=true;push_error("GRID_LIVE: "+message)
func _initialize() -> void:run.call_deferred()
func wait_player() -> void:
 for frame in range(500):
  if b.awaiting_player or not b.running:return
  await process_frame
 check(false,"clock returns player input")
func run() -> void:
 b=load("res://scenes/battle.tscn").instantiate();root.add_child(b);await process_frame;b.animation_time=.01
 b.player_stats={"strength":20,"agility":50,"constitution":20,"inner":20,"insight":20}
 b.set_loadout(["basic_attack","basic_defense","hoeryu","josik_suwon"])
 b.set_encounter({"id":"grid_fixture","name":"검증 무사","max_hp":500,"constitution":15,"stats":{"strength":15,"agility":30,"constitution":15,"inner":15,"insight":10},"weapon":"thickback_saber","skills":["soemok"],"field":{"width":9,"height":6,"blocked":[[4,2]]}})
 b.begin();await wait_player()
 check(b.grid.field.width==9 and b.grid.field.height==6 and b.grid_ui.visible,"production scene uses variable grid")
 check(b.status_cards[0].gauge.text.contains("행동력") and b.status_cards[1].gauge.text.contains("행동력"),"both actors show gauge")
 check(b.status_cards[0].gauge.tooltip_text.contains("오성"),"five existing stats remain available in status tooltip")
 check(b.intent_label.text=="" and not b.intent_label.visible,"old attack forecast removed")
 b.animation_time=.2
 var initial=b.grid.units[0].position;b.commit("move",initial+Vector2i.RIGHT)
 await create_timer(.025).timeout
 check(is_instance_valid(b.player_actor.walker) and not b.player_actor.sprite.visible,"movement uses articulated walking layer")
 check(b.player_actor.walker.pieces.all(func(part):return part.sprite.material==b.player_actor.sprite.material),"walking retains the same costume palette")
 await wait_player();check(b.grid.units[0].position==initial+Vector2i.RIGHT,"live movement updates model and actor")
 var old=b.grid.units[0].gauge;b.select_skill("hoeryu");check(b.grid.units[0].gauge==old,"selection spends nothing")
 check(b.metrics.text.contains("행동력 50"),"HUD shows actual action cost")
 var old_facing=b.facing;var rotate=InputEventKey.new();rotate.physical_keycode=KEY_R;rotate.pressed=true;b._input(rotate)
 check(b.facing!=old_facing and b.grid.units[0].gauge==old,"R rotates preview without spending gauge")
 b.cancel();await create_timer(.1).timeout;check(not b.running and not b.awaiting_player,"cancel stops queued work")
 b.set_encounter({"name":"흑린채 수적","constitution":5,"max_hp":150,"stats":{"strength":12,"agility":12,"constitution":5,"inner":6,"insight":5},"weapon":"thickback_saber","skills":["bandit_chop"],"field":{"player_spawn":[2,2],"enemy_spawn":[3,2]}})
 var victory_count=[0];b.victory.connect(func(_hp):victory_count[0]+=1)
 b.begin();await wait_player();b.grid.units[1].hp=1;b.select_skill("basic_attack");b.facing=Vector2i.RIGHT;b.use_selected()
 for frame in range(200):
  if not b.running:break
  await process_frame
 check(victory_count[0]==1 and b.enemy_hp==0,"victory reaches existing story signal once")
 b.queue_free();await process_frame;print("GRID_LIVE: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
