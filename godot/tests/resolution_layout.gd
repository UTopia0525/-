extends SceneTree
var game
var failed=false
var checks=0
var results=[]
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failed=true;push_error("RESOLUTION_LAYOUT: "+message)
func visible_bounds(node: Control,label: String) -> void:
 var view=root.get_visible_rect();var rect=node.get_global_rect()
 check(view.encloses(rect) or (view.grow(.5).encloses(rect)),label+" stays within logical viewport: "+str(rect))
func fit_text(node: Label,label: String) -> void:
 check(node.get_line_count()*node.get_line_height()<=node.size.y+2,label+" fits visible lines")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade"])
 for size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1600,900),Vector2i(1280,800),Vector2i(2560,1080)]:
  root.size=size;await process_frame;await process_frame
  game.start_city();game.progress.owned_weapons.assign(game.progress.weapons.definitions.keys());game.progress.learned.assign(game.progress.arts.definitions.keys());game.quest_navigation.track("changsha_cloth","deliver");game.chapter_number=1;await process_frame;await process_frame
  var view=root.get_visible_rect().size
  results.append({"window":[root.size.x,root.size.y],"logical":[view.x,view.y],"zoom":game.exploration.camera.zoom.x,"stretch":str(root.get_stretch_transform())})
  visible_bounds(game.minimap,"minimap");visible_bounds(game.quest_heading.get_parent(),"objective panel");visible_bounds(game.compact_toolbar,"help")
  check(game.exploration.background.material is ShaderMaterial,"terrain material installed")
  check(game.exploration.background.material.get_shader_parameter("world_size")==game.exploration.map_bounds.size,"terrain density follows real map bounds")
  check(is_equal_approx(game.exploration.camera.zoom.x,.8),"same exploration framing")
  for kind in ["inventory","martial"]:
   game.player_menu.open_menu(kind);await process_frame;visible_bounds(game.player_menu.action,kind+" action");visible_bounds(game.player_menu.heading,kind+" heading");game.player_menu.close_menu()
  game.adventure_ui.open_journal();visible_bounds(game.adventure_ui.panel,"journal");game.adventure_ui.close_menu()
  game.settings_menu.open_menu();visible_bounds(game.settings_menu.action,"save/load action");game.settings_menu.close_menu()
  for font in [0,1,2]:
   game.options.update("size",font)
   game.say([["hero","강호의 길은 멀고도 험하오. 장사에서 무창을 거쳐 남경에 이르기까지, 수많은 사람의 사정을 들었소. 누군가를 돕겠다는 마음만으로 모든 일이 풀리는 것은 아니었소. 그러니 이번에는 눈앞의 사정부터 찬찬히 살피고, 내가 책임질 수 있는 길을 찾으려 하오."]],Callable(),["hero","nj_vendor","nj_crowd_clerk_runner","nj_constable"])
   await process_frame;await process_frame
   visible_bounds(game.dialogue_panel,"dialogue");visible_bounds(game.dialogue_next,"next action");fit_text(game.dialogue_text,"long dialogue")
   game.advance_dialogue()
  game.options.update("size",1)
  game.start_battle();visible_bounds(game.battle.use_button,"battle action");visible_bounds(game.battle.skill_buttons[3],"battle fourth slot")
  game.reset();visible_bounds(game.title_screen.resume_button,"title continue");check(game.exploration.background.material==null,"prologue keeps original art rendering")
 print("RESOLUTION_LAYOUT_DATA "+JSON.stringify(results))
 game.queue_free();await process_frame;print("RESOLUTION_LAYOUT: "+("FAIL" if failed else "PASS")+" / checks="+str(checks));quit(1 if failed else 0)
