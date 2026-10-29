extends "res://tests/cuiyue_incident.gd"
const MID_IDS=["ganggeun_pill","yupung_pill","okgol_pill","baewon_pill"]
func open_shop() -> void:
 var definition=game.exploration.city_data.services.filter(func(s):return s.id=="city_merchant")[0]
 game.state="service";game.exploration.set_active(false);game.city_service.open_counter(definition)
func stock() -> Array:return game.city_service.rows.get_children().map(func(b):return b.get_meta("item_id",""))
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang();game.exploration.load_area("hangzhou")
 var p=game.progress;var shop=game.city_service;var w=game.exploration;var event=game.cuiyue_incident
 var old=p.snapshot()
 old.inventory.light_step_pill=1;old.consumed.light_step_pill=2
 for id in MID_IDS:old.inventory.erase(id);old.consumed.erase(id)
 check(p.valid(old),"old progress with four missing mid entries is accepted")
 p.restore(old)
 check(p.inventory.light_step_pill==1 and p.consumed.light_step_pill==2,"old lower-tier counters preserved")
 for id in MID_IDS:check(p.inventory[id]==0 and p.consumed[id]==0,"new slots default empty "+id)
 var capped=preload("res://scripts/player_progress.gd").new();capped.stats={"strength":200,"agility":200,"constitution":200,"inner":200,"insight":10};capped.inventory[MID_IDS[0]]=1
 check(not capped.consume(MID_IDS[0]) and capped.inventory[MID_IDS[0]]==1 and capped.consumed[MID_IDS[0]]==0,"stat cap never wastes a mid pill")
 var malformed=old.duplicate(true);malformed.inventory[MID_IDS[0]]=0;check(not p.valid(malformed),"half-missing new counter is rejected")
 p.reset();game.money=6000;p.add_favor("haomun",19);open_shop()
 check(stock().size()==4,"favor19 only has lower-tier stock")
 var purse=game.money
 check(not p.purchase("elixir",MID_IDS[0],game) and game.money==purse,"direct purchase cannot bypass favor19")
 shop.select_item(MID_IDS[0]);shop.transact();check(game.money==purse and shop.action.disabled,"forged selection cannot bypass favor gate")
 shop.close_counter();p.add_favor("haomun",1)
 # Actual F/topic/greeting path uses the updated merchant dialogue.
 var npc=w.ambient_nodes.filter(func(n):return n.get_meta("npc_id")=="hz_herbalist")[0]
 w.player.position=w.path_to(npc.position,true)[-1];w.player.stop();await frames();await press_f()
 check(game.adventure_ui.window.visible and game.adventure_ui.mode=="topics","favor20 opens merchant topics")
 var trade=game.adventure_ui.rows.get_children().filter(func(b):return b.get_meta("topic","")=="영약을 살펴본다")
 check(trade.size()==1,"merchant trade topic remains")
 if not trade.is_empty():trade[0].pressed.emit()
 check(JSON.stringify(game.dialogue_lines).contains("오백문"),"updated greeting explains price")
 await settle();check(shop.visible and game.state=="service" and stock().size()==8,"greeting opens expanded shop")
 for id in MID_IDS:
  check(id in stock() and preload("res://scripts/catalog_icons.gd").texture(id)!=null,"new item has stock and art "+id)
  shop.select_item(id);check(shop.action.text.contains("500") and shop.message.text.contains("0/3"),"correct price and lifetime limit "+id)
  for dose in range(3):shop.transact()
  check(p.inventory[id]==3 and p.consumed[id]==0,"buying never consumes medicine")
  var before=game.money;shop.transact();check(game.money==before and p.inventory[id]==3,"cannot overbuy lifetime allocation")
 check(game.money==0,"twelve pills cost6000")
 shop.close_counter();game.player_menu.open_menu("inventory");game.player_menu.select_item(MID_IDS[0])
 check(game.player_menu.visible and game.player_menu.detail.text.contains("0/3"),"I menu shows mid pill art/detail")
 game.player_menu.apply_selection();check(p.consumed[MID_IDS[0]]==1 and p.stats.strength==15 and p.stats.insight==10,"I consumption applies primary5 without insight")
 game.player_menu.close_menu();open_shop();shop.select_tab(1)
 for id in MID_IDS:
  shop.select_item(id)
  while p.inventory[id]>0:shop.transact()
  check(p.consumed[id]==3 and shop.action.disabled and shop.message.text.contains("3/3"),"three-use cap in counter "+id)
  var before=p.stats.duplicate();p.inventory[id]=1
  check(not p.consume(id) and p.stats==before and p.inventory[id]==1,"fourth consumption rejected without side effects")
  p.inventory[id]=0
 check(p.stats=={"strength":34,"agility":34,"constitution":34,"inner":34,"insight":10},"all twelve give24 each and96 total")
 shop.close_counter()
 # Other cities never stock mid pills, but owned medicines remain usable there.
 w.load_area("wuchang");open_shop();check(MID_IDS[0] not in stock(),"other city stock stays lower-tier")
 game.money=500;p.consumed[MID_IDS[0]]=2
 check(not p.purchase("elixir",MID_IDS[0],game) and p.error.contains("항주") and game.money==500,"wrong-city direct purchase rejected before charge")
 p.inventory[MID_IDS[0]]=1;p.consumed[MID_IDS[0]]=2;shop.select_tab(1)
 check(MID_IDS[0] in stock(),"owned medicine visible at other city's consume tab")
 shop.select_item(MID_IDS[0]);shop.transact();check(p.inventory[MID_IDS[0]]==0 and p.consumed[MID_IDS[0]]==3,"owned medicine consumption needs no shop unlock")
 shop.close_counter();w.load_area("hangzhou")
 # Referral is an actual hall-exit interaction, delivered once after completion.
 prepare_prereqs();p.learned.append("hoeryu");event.phase="completed";event.referral_seen=false;w.load_area("cuiyue_hall");await frames()
 check(game.save_system.write_slot(1),"completed old event can save before first referral")
 var exit=w.travel_exits[0];w.player.position=exit.position;w.player.stop();await frames();await press_f()
 check(w.area_name=="cuiyue_hall" and game.dialogue_cast.active_actor=="cy_waiter","F exit pauses for waiter")
 check(JSON.stringify(game.dialogue_lines).contains("두청하") and not event.referral_seen,"waiter names merchant before marking seen")
 check(not game.save_system.write_slot(2),"referral dialogue cannot save")
 await settle();check(w.area_name=="hangzhou" and event.referral_seen and w.active,"last line performs pending exit")
 check(game.save_system.write_slot(2) and game.save_system.load_slot(2) and event.referral_seen,"referral and lifetime doses restore")
 for id in MID_IDS:check(game.progress.consumed[id]==3,"load cannot reset three-dose cap")
 w.load_area("cuiyue_hall");await frames();w.player.position=w.travel_exits[0].position;w.player.stop();await frames();await press_f()
 check(w.area_name=="hangzhou" and game.dialogue_lines.is_empty(),"revisit exit does not repeat referral")
 var invalid=game.progress.snapshot();invalid.inventory[MID_IDS[0]]=1;check(not game.progress.valid(invalid),"save validation rejects fourth lifetime allocation")
 game.queue_free();await process_frame;print("MID_ELIXIRS: "+("FAIL" if failed else "PASS"));quit(1 if failed else 0)
