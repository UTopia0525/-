extends SceneTree
## Export the real common action calculations as an oracle for the offline browser simulator.
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var combat=preload("res://scripts/combat_actions.gd").new()
 var arts={}
 for id in ["basic_attack","basic_defense"]+combat.arts.definitions.keys():arts[id]=combat.arts.get_skill(id)
 var weapons=combat.weapons.definitions.duplicate(true);weapons.none={"name":"맨손","weapon_type":"none"}
 var samples=[{"strength":0,"agility":0,"constitution":0,"inner":0,"insight":0},{"strength":10,"agility":10,"constitution":10,"inner":10,"insight":10},{"strength":20,"agility":50,"constitution":20,"inner":20,"insight":20},{"strength":100,"agility":100,"constitution":100,"inner":100,"insight":100}]
 var oracle=[]
 for stats in samples:
  for weapon in weapons:
   for id in arts:
    var a=combat.action(id,stats,weapon);var hits=[]
    if not a.is_empty():
     for constitution in [0,14,100]:
      for guard in [0,20]:hits.append(combat.damage(a.raw,constitution,weapon,guard))
    oracle.append({"id":id,"stats":stats,"weapon":weapon,"action":a,"hits":hits})
 var folder=ProjectSettings.globalize_path("res://").path_join("../prototypes/grid-initiative-simulation")
 var f=FileAccess.open(folder.path_join("catalog.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"arts":arts,"weapons":weapons},"  "));f.close()
 f=FileAccess.open("user://grid-oracle.json",FileAccess.WRITE);f.store_string(JSON.stringify(oracle));f.close()
 print("GRID_CATALOG_EXPORT: PASS / ",oracle.size()," shared action cases / ",ProjectSettings.globalize_path("user://grid-oracle.json"));quit()
