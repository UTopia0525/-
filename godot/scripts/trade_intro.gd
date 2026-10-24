extends Node
## Three paid introductions: learning the shops never requires spending money first.
const IDS = ["changsha_cloth", "changsha_dishes", "changsha_handle"]
var game
var completed: Array = []
var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/trade_intro.json"))
var rewards: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/changsha_quest_rewards.json"))
func reset() -> void: completed.clear()
func active() -> bool:
 return game.chapter_one.intro_complete and completed.size() < IDS.size()
func current() -> Dictionary:
 return definitions.quests[completed.size()] if active() else {}
func handle_interaction(id: String) -> bool:
 var quest := current()
 if quest.is_empty() or quest.npc != id: return false
 game.pending_service_id = id
 game.say(quest.lines, _finish_visit)
 return true
func _finish_visit() -> void:
 var quest := current()
 if quest.is_empty() or game.pending_service_id != quest.npc: return
 var reward: Dictionary = rewards.quests[quest.id]
 game.money += int(reward.money)
 var before: int = game.progress.stats.insight
 game.progress.stats.insight = mini(100, before + int(reward.stat_gains.insight))
 completed.append(quest.id)
 game.adventure_ui.notify("의뢰 완료 · %d문 · 오성+%d" % [reward.money,game.progress.stats.insight-before],"quest")
 game.chapter_one.accepted_quests[quest.id] = {"status":"completed", "stage":"done"}
 if active():
  var next := current()
  game.chapter_one.accepted_quests[next.id] = {"status":"active", "stage":next.stage}
 sync_navigation()
 game._service_done()
 game.city_service.feedback.text = "의뢰 완료 · %d문 · 오성+%d  |  %s" % [reward.money, game.progress.stats.insight - before, "다음 목적지는 미니맵을 확인하세요." if active() else "거래 안내 완료 · I 소지품 / K 무공"]
func sync_navigation() -> void:
 var nav = game.quest_navigation
 if not game.chapter_one.intro_complete: return
 if nav.quest_id != "" and nav.quest_id not in IDS: return
 if active():
  var quest := current()
  nav.track(quest.id, quest.stage)
 elif nav.quest_id in IDS: nav.clear()
func quest_items() -> Array:
 var quest := current()
 return [quest.item] if not quest.is_empty() else []
func snapshot() -> Dictionary: return {"completed":completed.duplicate()}
func valid(data) -> bool:
 if not data is Dictionary or not data.get("completed") is Array or data.completed.size() > 3: return false
 return data.completed == IDS.slice(0, data.completed.size())
func restore(data: Dictionary) -> void:
 completed = data.get("completed", []).duplicate()
 sync_navigation()
