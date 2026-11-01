extends "res://tests/isometric_performance.gd"
## Real rendered comparison of the retained district and the new bounded town.
func run() -> void:
 create_timer(300).timeout.connect(func():push_error("TOWN_PERF watchdog");quit(2))
 root.size=Vector2i(1280,720)
 var reports={}
 for scene in ["district","changsha"]:
  host=load("res://prototypes/isometric/"+scene+".tscn").instantiate();root.add_child(host);await settle()
  results=[]
  for label in ["idle","player_diagonal","all_follow"]:
   configure(label);await settle();await measure(label)
  reports[scene]={"size":host.map_size,"actors":host.moving_actors.size(),"buildings":host.props.filter(func(p):return p.spec.kind=="building").size(),"props":host.props.size(),"results":results.duplicate(true)}
  await remove_host()
 var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify({"godot":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),"resolution":"1280x720","zoom":.85,"physics_hz":60,"sample_count":sample_count,"software_threads":OS.get_environment("LP_NUM_THREADS"),"scenes":reports},"  "));file.close()
 print("TOWN_PERF_SAVED ",output);quit()
