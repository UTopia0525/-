extends SceneTree
## Rendered, wall-clock benchmark; no fixed FPS and no video capture.
## Run identical arguments before/after; software-renderer numbers are not PC FPS.
const Space=preload("res://prototypes/isometric/iso_space.gd")
var host
var samples=[]
var tick=0
var scenario=""
var results=[]
var output="/tmp/isometric-performance.json"
var sample_count=90
var only=""
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
  if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
  if arg.begins_with("--samples="):sample_count=int(arg.trim_prefix("--samples="))
 run.call_deferred()
func _physics_process(_delta: float) -> bool:
 if not is_instance_valid(host):return false
 tick+=1
 if scenario in ["player_horizontal","player_diagonal","all_follow","all_fixed","room_walk"]:
  var reverse=1 if (tick/30)%2==0 else -1
  var diagonal=scenario in ["player_diagonal","all_follow","all_fixed"]
  var direction=Vector2(reverse,-reverse if diagonal else 0)
  Input.action_press("iso_right",maxf(direction.x,0));Input.action_press("iso_left",maxf(-direction.x,0))
  Input.action_press("iso_down",maxf(direction.y,0));Input.action_press("iso_up",maxf(-direction.y,0))
 return false
func clear_input() -> void:
 for key in ["iso_left","iso_right","iso_up","iso_down"]:
  if InputMap.has_action(key):Input.action_release(key)
func stat(values: Array) -> Dictionary:
 var sorted=values.duplicate();sorted.sort();var total=0.0;var over=0
 for value in values:total+=value;over+=int(value>33.333)
 return {"mean_ms":total/values.size(),"p95_ms":sorted[int((values.size()-1)*.95)],"p99_ms":sorted[int((values.size()-1)*.99)],"max_ms":sorted.back(),"over_33_ms":over,"count":values.size()}
func measure(label: String,count: int=0) -> Dictionary:
 var deltas=[];var cpu=[];var physics=[]
 var last=Time.get_ticks_usec()
 for i in range(count if count>0 else sample_count):
  await process_frame
  var now=Time.get_ticks_usec();deltas.append((now-last)/1000.0);last=now
  cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
  physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
 var entry={"scenario":label,"frame":stat(deltas),"engine_process":stat(cpu),"engine_physics":stat(physics)}
 results.append(entry);print("PERF ",JSON.stringify(entry));return entry
func settle() -> void:
 for i in range(25):await process_frame
func district() -> void:
 clear_input();host=load("res://prototypes/isometric/district.tscn").instantiate();root.add_child(host);await settle()
func remove_host() -> void:
 clear_input();scenario="";host.queue_free();host=null
 for i in range(3):await process_frame
func configure(label: String) -> void:
 clear_input();scenario=label;tick=0
 host.patrols_enabled=label in ["npc_only","all_follow","all_fixed"]
 host.follow=label!="all_fixed"
 host.actor.set_logical(Vector2(9.7,11.1) if label!="player_horizontal" else Vector2(8.7,11.5))
 if label=="room_walk":host.actor.set_logical(Vector2(5.2,3.6))
 host.snap_camera()
func timing(call: Callable,iterations=40) -> Dictionary:
 var times=[]
 for i in range(iterations):
  var start=Time.get_ticks_usec();call.call();times.append((Time.get_ticks_usec()-start)/1000.0)
 return stat(times)
func kernels() -> Dictionary:
 scenario="";clear_input();host.patrols_enabled=false
 for i in range(host.moving_actors.size()):
  var a=host.moving_actors[i];a.set_logical(Vector2(10.3,12.8)+Vector2(i*.5,0));a.moving=true;a.set_pose("front",false)
 var a=host.actor
 var result={}
 result.mesh_pose=timing(func():a.rig.pose(a.images.front,a.hit_images.front,"front",a.rig.gait+.08))
 result.depth_sort=timing(func():host.last_sorted_positions=[];host.update_depth())
 result.occlusion=timing(func():host.update_occlusion())
 result.npc_selection=timing(func():host.interaction.choose_target())
 result.camera=timing(func():host.snap_camera())
 return result
func run() -> void:
 create_timer(600).timeout.connect(func():push_error("PERF timeout");quit(2))
 root.size=Vector2i(1280,720)
 if only=="room_walk":
  for repeat in range(3):
   host=load("res://prototypes/isometric/room.tscn").instantiate();root.add_child(host);await settle()
   configure("room_walk");await settle();await measure("room_walk_repeat_"+str(repeat+1));await remove_host()
  save_report({});quit();return
 await district()
 var kernel=kernels();print("KERNEL ",JSON.stringify(kernel))
 for label in ["idle","player_horizontal","player_diagonal","npc_only","all_follow","all_fixed"]:
  configure(label);await settle();await measure(label)
 scenario="";clear_input();host.patrols_enabled=false
 for npc in host.npcs:npc.set_logical(Vector2(19,14))
 host.actor.set_logical(Vector2(14.605814,11.562791));await settle()
 var p=host.passage
 # Include real entry/exit allocations, fades and NPC/camera restoration.
 var transition_samples=[]
 var watch=func():transition_samples.append(Time.get_ticks_usec())
 process_frame.connect(watch)
 for cycle in range(3):
  p.require_release=false;p.transition();await p.completed
  p.room.actor.set_logical(Vector2(4,5.1));p.require_release=false;p.transition();await p.completed
 process_frame.disconnect(watch)
 var transition_deltas=[]
 for i in range(1,transition_samples.size()):transition_deltas.append((transition_samples[i]-transition_samples[i-1])/1000.0)
 results.append({"scenario":"entry_exit_3_roundtrips","frame":stat(transition_deltas)})
 # Repeated dialogue/history and journal changes with actual existing UI.
 host.actor.set_logical(host.npcs[1].logical+Vector2(.6,0));await settle()
 for kind in ["dialogue_history","journal"]:
  var deltas=[];var last=Time.get_ticks_usec()
  for i in range(sample_count):
   if i%30==0:
    if kind=="journal":host.errand.open_journal()
    else:host.dialogue.begin(host.npcs[1])
   if i%30==10 and kind=="dialogue_history":host.dialogue.dialogue_history.open_history()
   if i%30==20:
    if kind=="journal":host.errand.close_journal()
    else:host.dialogue.finish()
   await process_frame
   var now=Time.get_ticks_usec();deltas.append((now-last)/1000.0);last=now
  results.append({"scenario":kind,"frame":stat(deltas)})
 await remove_host()
 host=load("res://prototypes/isometric/room.tscn").instantiate();root.add_child(host);await settle()
 configure("room_walk");await settle();await measure("room_walk")
 save_report(kernel)
 await remove_host();print("PERF_SAVED ",output);quit()

func save_report(kernel: Dictionary) -> void:
 var report={"godot":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),"resolution":"1280x720","zoom":.85,"physics_hz":Engine.physics_ticks_per_second,"sample_count":sample_count,"software_threads":OS.get_environment("LP_NUM_THREADS"),"fixed_delta_used":false,"kernels":kernel,"results":results}
 var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
