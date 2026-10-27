extends RefCounted
## K preparation layout; changes presentation only, not the combat rules.
const UI=preload("res://scripts/ui.gd")
const Icons=preload("res://scripts/catalog_icons.gd")
const RangePreview=preload("res://scripts/martial_range_preview.gd")
static func qi_cost(m,id: String) -> int:
 var item=m.progress.arts.get_skill(id)
 return m.progress.weapons.qi_cost(int(item.get("qi_cost",0)),m.game.battle.equipped_weapon_id,item)
static func build(m,ids: Array) -> void:
 for i in range(4):
  var id: String=m.progress.loadout[i];var slot=m.button("",Rect2(90+i*277,139,261,113));m.slots.append(slot)
  m.selected_style(slot,i==m.target_slot);slot.pressed.connect(m.select_slot.bind(i));slot.set_meta("item_id",id)
  slot.icon=Icons.texture(id);slot.expand_icon=true;slot.add_theme_constant_override("icon_max_width",1)
  m.icon(slot,id,Rect2(11,27,64,64));m.text(slot,str(i+1),Rect2(226,7,26,22),14,m.MUTED)
  m.text(slot,"비어 있음" if id.is_empty() else str(m.progress.arts.get_skill(id).name),Rect2(85,19,163,28),18,m.INK)
  if id.is_empty():m.text(slot,"무공 선택 후 편성",Rect2(85,58,163,35),13,m.MUTED)
  else:
   m.text(slot,"행동 %s · 내기 %d" % [m.tactics.action_cost_text(id),qi_cost(m,id)],Rect2(85,52,163,23),13,m.TEAL)
   m.text(slot,m.tactics.summary_text(id),Rect2(85,77,163,22),13,m.MUTED)
  slot.tooltip_text="%d번 편성 · %s" % [i+1,"비어 있음" if id.is_empty() else m.progress.arts.get_skill(id).name]
 for i in range(6):
  var value=["all","sword","saber","spear","unarmed","support"][i]
  var tab=m.button(["전체","검","도","창","맨손","보조"][i],Rect2(90+i*68,277,62,32))
  UI.selection(tab,m.art_filter==value,true,true);m.tabs.append(tab);tab.pressed.connect(m.select_filter.bind(value))
 m.scroll_area(Rect2(90,331,480,273),false)
 for id in ids:
  var item=m.progress.arts.get_skill(id)
  var row=m.button("%s\n행동 %s · 내기 %d" % [item.name,m.tactics.action_cost_text(id),qi_cost(m,id)],Rect2(0,0,466,68))
  row.reparent(m.rows);row.custom_minimum_size=Vector2(466,68);row.clip_text=true;row.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  row.add_theme_font_size_override("font_size",16);row.icon=Icons.texture(id);row.expand_icon=true;row.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT;row.alignment=HORIZONTAL_ALIGNMENT_LEFT
  row.add_theme_constant_override("icon_max_width",44);row.add_theme_constant_override("h_separation",12)
  m.selected_style(row,id==m.selected_id);UI.item_highlight(row);row.set_meta("item_id",id)
  row.tooltip_text=str(item.description);row.pressed.connect(m.select_item.bind(str(id)))
  if id in m.progress.loadout:m.text(row,"편성 %d" % [m.progress.loadout.find(id)+1],Rect2(372,7,85,21),12,m.TEAL)
 var clear=m.button("선택한 편성 칸 비우기",Rect2(0,0,466,43));clear.reparent(m.rows);clear.custom_minimum_size=Vector2(466,43);clear.pressed.connect(m.select_item.bind("clear"))
 if ids.is_empty():m.text(m.rows,"해당 종류의 익힌 무공이 없습니다.",Rect2(0,0,460,38),17,m.MUTED)
 m.line(Rect2(595,279,1,325))
 m.action=m.button("선택하세요",Rect2(635,565,525,44),true);m.action.pressed.connect(m.apply_selection)
 m.detail=m.rich(Rect2(912,424,248,130));m.detail.add_theme_font_size_override("normal_font_size",14)
 if m.selected_id.is_empty():m.detail.text="익힌 무공과 편성할 칸을 고르세요.";m.action.disabled=true;return
 if m.selected_id=="clear":
  m.text(m.content,"초식 비우기",Rect2(633,278,420,46),31,m.INK,true)
  m.detail.position=Vector2(635,418);m.detail.size=Vector2(525,130)
  m.detail.text="선택한 칸만 비웁니다. 기본공격·기본방어도 바꿀 수 있습니다.";m.action.text="%d번 칸 비우기" % [m.target_slot+1];return
 var id: String=m.selected_id;var item=m.progress.arts.get_skill(id);var tactics=m.tactics.get_tactics(id)
 m.text(m.content,str(item.name),Rect2(633,273,440,41),29,m.INK,true)
 m.text(m.content,{"sword":"검법","saber":"도법","spear":"창법","fist":"권법","palm":"장법","support":"보조 무공","basic":"기본 행동"}.get(item.weapon_style,"무공")+" · "+m.progress.arts.weapon_requirement(id),Rect2(635,315,440,24),14,m.MUTED)
 m.icon(m.content,id,Rect2(1087,274,74,67))
 var values=[m.tactics.action_cost_text(id),str(qi_cost(m,id)),"도식 참고"]
 for i in range(3):
  var pos=Vector2(635+i*180,346);m.box(m.content,Rect2(pos,Vector2(165,57)),Color("e4dac4"))
  m.text(m.content,["행동력 소모","내기 소모","기술 범위"][i],Rect2(pos+Vector2(11,4),Vector2(143,20)),12,m.MUTED)
  var value=m.text(m.content,values[i],Rect2(pos+Vector2(11,24),Vector2(143,30)),22,m.INK)
  m.martial_metrics.append(value)
 m.box(m.content,Rect2(635,423,250,132),Color("e8dfcd"))
 m.range_preview=RangePreview.new();m.range_preview.position=Vector2(635,423);m.range_preview.size=Vector2(250,132);m.content.add_child(m.range_preview)
 m.range_preview.configure(m.tactics.preview(id));m.range_preview.tooltip_text="오른쪽으로 펼치는 범위 예시입니다. 지형과 점유에 따라 이동이 막힐 수 있습니다."
 m.text(m.content,"범위 예시 · 우측",Rect2(635,404,250,18),11,m.MUTED)
 var grade={"introductory":"입문","low":"하급","intermediate":"중급"}.get(item.get("grade",""),"기본")
 var body=str(grade)+" · "+str(tactics.target)+"\n"+str(tactics.description)
 if not item.damage_coefficients.is_empty():
  var parts: Array[String]=[]
  if int(item.get("base_damage",0))>0:parts.append(str(int(item.base_damage)))
  for key in item.damage_coefficients:parts.append({"strength":"근력","inner":"내공","agility":"기민"}.get(key,key)+"×"+str(item.damage_coefficients[key]))
  body+="\n위력 "+" + ".join(parts)
 if item.weapon_style=="support":body+="\n내공의 %d%% 내기 회복\n피해 %d%% 감소 · 재사용 %d행동" % [int(item.get("qi_restore_inner_percent",0)),int(item.get("guard_percent",0)),int(item.get("cooldown_turns",0))]
 elif item.weapon_style=="sword" or id=="basic_defense":body+="\n피해 20% 감소"
 if item.get("requirements",{}).get("minimum_total",-1)==0 and item.requirements.stats.is_empty():body+="\n능력치·경지 학습 조건 없음"
 m.detail.text=body
 if not m.progress.arts.can_use_with_weapon(id,m.game.battle.equipped_weapon_type):
  m.detail.push_color(Color("9c4b3d"));m.detail.add_text("\n! "+m.progress.arts.weapon_requirement(id)+" · I에서 장비를 바꾸세요.");m.detail.pop()

 m.action.text="%d번 칸에 편성" % [m.target_slot+1]
