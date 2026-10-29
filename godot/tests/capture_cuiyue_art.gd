extends "res://tests/capture_exploration_sprites.gd"
func run() -> void:
 var data: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/exploration_sprite_inventory.json"))
 var names=["공용 무인 · 서문길","남궁세가 일반 무인","남궁서진","탁문호","은소월"]
 var view=viewport(Vector2i(1440,570))
 label(view,"탐험 도트 · 기존 기준과 수정본",Rect2(20,18,1400,45),30)
 label(view,"같은 도시 표시 배율 ×2 · 같은 발밑선 · 공용/남궁 비율과 픽셀 표현 비교",Rect2(20,66,1400,32),20)
 for i in range(names.size()):
  var n: Dictionary=data.filter(func(entry):return entry.name==names[i])[0]
  var x=20+i*280;panel(view,Rect2(x,115,268,420))
  var region=Rect2(n.region[0],n.region[1],n.region[2],n.region[3]);var atlas=AtlasTexture.new();atlas.atlas=load(n.texture);atlas.region=region
  var sprite=Sprite2D.new();sprite.texture=atlas;sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  sprite.offset=Vector2(-region.size.x/2,-region.size.y);sprite.position=Vector2(x+134,425)
  sprite.scale=Vector2.ONE*minf(METRICS.CITIZEN_HEIGHT/region.size.y,88.0/region.size.x)*2;view.add_child(sprite)
  var line=ColorRect.new();line.position=Vector2(x+14,425);line.size=Vector2(240,2);line.color=Color("bca877");view.add_child(line)
  label(view,n.name,Rect2(x,443,268,32),22)
  label(view,"기존 기준" if i<3 else "수정본",Rect2(x,485,268,26),18)
 await save(view,"res://screenshots/cuiyue-art-comparison.png")
 view.queue_free();await process_frame
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.options.seen.append_array(["city","dialogue","trade","battle"]);game.start_wuchang()
 game.exploration.load_area("cuiyue_hall");game.cuiyue_incident.phase="confront";game.cuiyue_incident.refresh_world()
 game.exploration.player.position=game.exploration.city_point([900,600]);game.exploration.camera.snap_to_player()
 game.state="story";game.cuiyue_incident.track();game.say(game.cuiyue_incident.data.scenes.confront);game.advance_dialogue()
 for i in range(6):await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://screenshots/cuiyue-tak-portrait.png")==OK)
 game.queue_free();await process_frame
 print("CUIYUE_ART_CAPTURE: PASS");quit()
