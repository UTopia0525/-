extends SceneTree
## Memory-only definitions; no scene, NPC, dialogue or UI expansion.
const Errands=preload("res://prototypes/isometric/iso_town_errands.gd")
var failed=false
var checks=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failed=true;push_error("ISO_TOWN_STATE: "+message)
func same_keys(a: Dictionary,b: Dictionary) -> bool:
 return a.size()==b.size() and a.keys().all(func(id):return b.has(id))
func fresh(definitions: Dictionary):
 var q=Errands.new();q.definitions=definitions.duplicate(true);return q
func _initialize() -> void:
 var probe=Errands.new();var source=probe.definitions.duplicate(true)
 if not probe.has_method("initialize_quests"):
  check(false,"definition-driven initialization missing; initial state has separately written IDs")
  probe.free();quit(1);return
 probe.free()
 var q=fresh(source)
 check(q.initialize_quests(),"valid definitions accepted")
 check(same_keys(source,q.phases) and same_keys(source,q.completions),"exact definition/state/count keys")
 check(q.phases.values().all(func(value):return value=="available") and q.completions.values().all(func(value):return value==0),"all quests start available with zero completions")
 check(q.selected_quest==source.keys()[0] and q.navigation==null,"initial selection follows definitions; initialization does not create tracking")
 var renamed=source.duplicate(true);var first=renamed.keys()[0];var content=renamed[first];renamed.erase(first);renamed["memory_renamed"]=content
 var other=fresh(renamed);other.initialize_quests()
 check(same_keys(renamed,other.phases) and same_keys(renamed,other.completions) and not other.phases.has(first),"renamed ID propagates without old key")
 other.free()
 var expanded=source.duplicate(true);expanded["memory_only"]=source[first].duplicate(true)
 other=fresh(expanded);other.initialize_quests()
 check(same_keys(expanded,other.phases) and same_keys(expanded,other.completions) and other.phases.memory_only=="available" and other.completions.memory_only==0,"temporary third definition registered only in memory")
 other.phases[first]="active";other.completions[first]=2;other.initialize_quests()
 check(other.phases.memory_only=="available" and other.completions.memory_only==0 and other.phases[first]=="active" and other.completions[first]==2,"independent state and repeated active initialization")
 other.phases[first]="completed";other.completions[first]=3;other.initialize_quests()
 check(other.phases[first]=="completed" and other.completions[first]==3,"completed state/count survive repetition")
 other.phases.memory_only="ready";other.initialize_quests()
 check(other.phases.memory_only=="ready","ready state survives repetition")
 other.free()
 other=fresh(source);other.initialize_quests();other.phases[first]="active";other.completions[first]=1
 other.definitions["memory_late"]=source[first].duplicate(true);other.initialize_quests()
 check(same_keys(other.definitions,other.phases) and same_keys(other.definitions,other.completions) and other.phases.memory_late=="available" and other.completions.memory_late==0 and other.phases[first]=="active" and other.completions[first]==1,"later memory definition fills missing entries without resetting progress")
 var saved_phases=other.phases.duplicate();var saved_counts=other.completions.duplicate();var saved_selection=other.selected_quest
 other.definitions[""]={}
 check(not other.initialize_quests() and other.phases==saved_phases and other.completions==saved_counts and other.selected_quest==saved_selection,"invalid retry preserves existing progress and selection")
 other.free()
 var reversed={};var ids=source.keys();ids.reverse()
 for id in ids:reversed[id]=source[id].duplicate(true)
 other=fresh(reversed);other.phases[ids[0]]="ready";other.completions[ids[0]]=4;other.initialize_quests()
 check(other.phases[ids[0]]=="ready" and other.completions[ids[0]]==4 and other.phases[ids[1]]=="available" and other.completions[ids[1]]==0,"order and partially initialized dictionaries retain ID association")
 check(other.selected_quest==ids[0],"first defined quest selected without hardcoded ID")
 other.selected_quest=ids[1];other.initialize_quests();check(other.selected_quest==ids[1],"reinitialization preserves selection")
 other.free()
 for bad in ["", " ", " padded", 17, "bad-id", "17bad", "trailing\n", "한글"]:
  var invalid=source.duplicate(true);invalid[bad]={};other=fresh(invalid)
  check(not other.initialize_quests() and other.phases.is_empty() and other.completions.is_empty() and other.selected_quest=="","invalid ID rejected atomically: "+str(bad))
  other.free()
 other=fresh({});check(other.initialize_quests() and other.phases.is_empty() and other.completions.is_empty() and other.selected_quest=="","empty definitions are a successful no-op without selection")
 other.free()
 var phases=q.phases.duplicate();var counts=q.completions.duplicate()
 q.resolve_for("unknown_id","accept")
 check(q.phases==phases and q.completions==counts,"unknown action ID cannot register state")
 q.phases[first]="active";q.completions[first]=1;q.definitions={};q.initialize_quests()
 check(q.phases[first]=="active" and q.completions[first]==1,"empty retry does not clear existing state")
 check(source==JSON.parse_string(FileAccess.get_file_as_string("res://prototypes/isometric/town-quests.json")),"real definition file unchanged")
 q.free()
 print("ISOMETRIC_TOWN_STATE: "+("FAIL" if failed else "PASS")+" | checks="+str(checks));quit(1 if failed else 0)
