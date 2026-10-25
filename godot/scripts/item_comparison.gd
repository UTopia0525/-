extends RefCounted
const NAMES={"strength":"근력","agility":"기민","constitution":"근골","inner":"내공","insight":"오성"}
static func weapon(progress,id: String,equipped: String) -> String:
	var selected: Dictionary=progress.weapons.get_weapon(id);var current: Dictionary=progress.weapons.get_weapon(equipped)
	return "현재 장비와 비교 · %s\n해당 무공 공격 보정 %+d%%p · 피해 감소 %+d%%p · 창법 내기 절감 %+d%%p" % [current.get("name","맨손"),int(selected.get("attack_bonus_percent",0))-int(current.get("attack_bonus_percent",0)),int(selected.get("damage_reduction_percent",0))-int(current.get("damage_reduction_percent",0)),int(selected.get("qi_reduction_percent",0))-int(current.get("qi_reduction_percent",0))]
static func art(progress,id: String,equipped: String) -> Array[String]:
	var lines: Array[String]=[];var skill: Dictionary=progress.arts.get_skill(id)
	if id in ["basic_attack","basic_defense"]:return lines
	if skill.weapon_style=="support":
		lines.append("내공의%d%%만큼 내기 회복 · 현재 %d\n상대 피해%d%% 감소 · 사용 후%d턴 재사용 불가" % [skill.qi_restore_inner_percent,progress.arts.qi_recovery(id,progress.stats),skill.guard_percent,skill.cooldown_turns])
	else:lines.append("무기 보정 전 위력 %.0f · 삼재검법 대비 %+.0f" % [progress.arts.raw_damage(id,progress.stats),progress.arts.raw_damage(id,progress.stats)-progress.arts.raw_damage("samjae",progress.stats)])
	var total:=0
	for value in progress.stats.values():total+=int(value)
	for key in skill.requirements.stats:
		var need: int=skill.requirements.stats[key];var have: int=progress.stats[key]
		lines.append(("[충족] " if have>=need else "[부족] ")+"%s %d/%d" % [NAMES[key],have,need])
	if skill.requirements.stats.is_empty() and int(skill.requirements.minimum_total)==0:
		lines.append("[충족] 능력치·경지 학습 조건 없음")
	else:
		lines.append(("[충족] " if total>=int(skill.requirements.minimum_total) else "[부족] ")+"능력 합계 %d/%d" % [total,int(skill.requirements.minimum_total)])
	var usable: bool=progress.arts.can_use_with_weapon(id,progress.weapons.weapon_type(equipped))
	if usable:lines.append("현재 장비 적용 내기 %d · 기본 %d" % [progress.weapons.qi_cost(int(skill.qi_cost),equipped,skill),int(skill.qi_cost)])
	lines.append(("[충족] " if usable else "[부족] ")+progress.arts.weapon_requirement(id))
	return lines
static func append_art(view: RichTextLabel,progress,id: String,equipped: String) -> void:
	view.add_text("\n\n")
	for line in art(progress,id,equipped):
		view.push_color(Color("f8a494") if line.begins_with("[부족]") else Color("b5d8ac") if line.begins_with("[충족]") else Color("eee8d8"))
		view.add_text(line+"\n");view.pop()
