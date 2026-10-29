extends RefCounted
## Reviewed, deterministic dialogue cues. Unknown/new lines keep the approved neutral face.
const MOODS=["neutral","smile","angry","sad","surprised"]
var registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/portrait_expressions.json"))
var cues: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue_expression_cues.json"))
var cache: Dictionary={}
func sheet_for(base: String) -> Texture2D:
	if not registry.portraits.has(base):return null
	if not cache.has(base):
		var path: String=registry.portraits[base].sheet
		cache[base]=load(path) if ResourceLoader.exists(path) else null
	return cache[base]
func staging_for(line: Array) -> Dictionary:
	var staging: Dictionary={}
	if line.size()>2 and line[2] is Dictionary:staging=line[2].duplicate(true)
	if line.size()>3 and line[3] is Dictionary:staging=line[3].duplicate(true)
	if not staging.has("emotion"):
		staging.emotion=cues.lines.get(str(line[0])+"|"+str(line[1]),"neutral")
	return staging
func staging_at(lines: Array,index: int) -> Dictionary:
	var states: Dictionary={}
	# Reconstruct presentation only through the current line, including after a
	# legacy dialogue load or a portrait layout rebuild. Never inspect future lines.
	for i in range(index+1):
		var cue=staging_for(lines[i])
		states[str(lines[i][0])]=str(cue.emotion)
		states.merge(cue.get("emotions",{}),true)
	var current=staging_for(lines[index]);current.emotions=states
	return current
