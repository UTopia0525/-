extends RefCounted
## Layered art trial: floor, individually sorted scenery and physical footprints.
static func install(world) -> void:
 var specs = [
  ["dock_herb_shop",[65,0,320,260],[0,0,768,512],[[.13,.72,.75,.23]]],
  ["dock_warehouse",[400,-20,350,270],[768,0,768,512],[[.12,.74,.77,.22]]],
  ["dock_willow",[25,310,175,225],[0,512,768,512],[[.44,.88,.13,.10]]],
  ["escort_ship",[940,85,330,310],[768,512,768,512],[[.28,.78,.50,.12]]]
 ]
 specs.append(["quay_west_neighbor",[-170,80,260,245],[0,0,768,512],[[.13,.72,.75,.23]]])
 specs.append(["quay_foreground_shop",[-60,570,325,255],[768,0,768,512],[[.12,.74,.77,.22]]])
 for spec in specs:
  var node=preload("res://scripts/city_scenery.gd").new()
  node.configure({"id":spec[0],"rect":spec[1]},{"texture":"res://assets/maps/prologue-dock/scenery.png","source":spec[2],"kind":"tree" if spec[0]=="dock_willow" else "boat" if spec[0]=="escort_ship" else "building","footprints":spec[3]},Vector2.ONE)
  world.decorations.add_child(node);world.occlusion_roots.append(node);world.scenery_nodes.append(node);world.scenery_bounds.append(node.visual_rect)
  world.blockers.append_array(node.collision_rects)
 var props: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/nanjing/layout.json")).prefabs
 for entry in [["quay_cart","capital_grain_cart",[460,555,110,80]],["herb_pots","capital_planter",[210,260,42,40]],["warehouse_pots","capital_planter",[658,250,42,40]]]:
  var prop=preload("res://scripts/city_scenery.gd").new()
  prop.configure({"id":entry[0],"rect":entry[2]},props[entry[1]],Vector2.ONE)
  world.decorations.add_child(prop);world.occlusion_roots.append(prop);world.scenery_nodes.append(prop);world.scenery_bounds.append(prop.visual_rect);world.blockers.append_array(prop.collision_rects)
 world.city_data["art_size"]=[1280,720]
 for node in world.scenery_nodes:
  world.art_tiles.append({"texture":node.sprite.texture.atlas,"source":node.sprite.texture.region,"target":node.visual_rect})
 # A sparse wake is animated independently of the baked floor.
 var water=Node2D.new();water.set_script(load("res://scripts/prologue_water.gd"));world.background.add_child(water)
