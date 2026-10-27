extends "res://scripts/paper_menu_base.gd"
## Live possessions and four-slot preparation in the approved paper layout.
var game
var tactics=preload("res://scripts/martial_tactics.gd").new()
var martial_metrics: Array[Label]=[]
var range_preview: Control
var mode:="inventory"
var category:="all"
var selected_id:=""
var target_slot:=0
var art_filter:="all"
var progress
var heading: Label
var summary: Label
var detail: RichTextLabel
var feedback: Label
var rows: Control
var action: Button
var tabs: Array[Button]=[]
var slots: Array[Button]=[]
var list_scroll: ScrollContainer
var memory: Dictionary={}
var message:=""
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;z_index=20;hide()
func open_menu(value: String) -> void:
 if visible:
  if value==mode:close_menu()
  else:switch_mode(value)
  return
 if game.state!="explore" or not game.dialogue_lines.is_empty() or game.city_overview.visible or game.city_service.visible or game.settings_menu.window.visible:return
 game.exploration.set_active(false);show();switch_mode(value);focus_selection()
func remember() -> void:
 if is_instance_valid(list_scroll):memory[mode]={"category":category,"selected":selected_id,"filter":art_filter,"scroll":list_scroll.scroll_vertical}
func switch_mode(value: String) -> void:
 if is_instance_valid(content):remember()
 mode=value;var state: Dictionary=memory.get(mode,{})
 category=state.get("category","all") if mode=="inventory" else "art";art_filter=state.get("filter","all");selected_id=state.get("selected","");message="";refresh()
 if is_instance_valid(list_scroll):list_scroll.set_deferred("scroll_vertical",int(state.get("scroll",0)))
func close_menu() -> void:
 if not visible:return
 remember();hide()
 if game.state=="explore" and game.dialogue_lines.is_empty() and not game.city_overview.visible and not game.city_service.visible:game.exploration.set_active(true)
func dismiss() -> void:remember();hide()
func select_category(value: String) -> void:category=value;selected_id="";message="";refresh()
func select_filter(value: String) -> void:art_filter=value;selected_id="";message="";refresh()
func select_slot(index: int) -> void:
 if mode!="martial" or index<0 or index>3:return
 target_slot=index;refresh();slots[target_slot].grab_focus()
func select_item(id: String) -> void:selected_id=id;message="";refresh();focus_selection()
func weapon_name() -> String:return str(game.progress.weapons.get_weapon(game.battle.equipped_weapon_id).get("name","맨손"))
func item_kind(id: String) -> String:
 if mode=="martial":return "art"
 if id=="none" or id in game.progress.owned_weapons:return "weapon"
 if game.progress.elixirs.has(id):return "elixir"
 if game.progress.manual_definitions.has(id):return "manual"
 return "quest"
func item_name(id: String) -> String:
 var p=game.progress
 match item_kind(id):
  "art":return "칸 비우기" if id=="clear" else str(p.arts.get_skill(id).name)
  "weapon":return "맨손" if id=="none" else str(p.weapons.get_weapon(id).name)
  "elixir":return str(p.elixirs[id].name)
  "manual":return str(p.manual_definitions[id].name)
 return id
func visible_ids() -> Array:
 var p=game.progress;var result=[]
 if mode=="martial":
  for id in ["basic_attack","basic_defense"]+p.learned:
   if art_filter=="all" or p.arts.get_skill(id).weapon_style==art_filter:result.append(id)
  return result
 if category in ["all","weapon"]:result.append_array(p.owned_weapons+["none"])
 if category in ["all","elixir"]:
  for id in p.inventory:
   if p.inventory[id]>0:result.append(id)
 if category in ["all","manual"]:
  for id in p.manuals:
   if p.manuals[id]>0:result.append(id)
 if category in ["all","quest"]:result.append_array(game.trade_intro.quest_items())
 return result
func selected_style(b: Button,chosen: bool) -> void:
 UI.selection(b,chosen,true)
func refresh() -> void:
 progress=game.progress;var old_scroll=0
 if is_instance_valid(list_scroll):old_scroll=list_scroll.scroll_vertical
 if is_instance_valid(content):remove_child(content);content.queue_free()
 tabs.clear();slots.clear();martial_metrics.clear();range_preview=null;content=Control.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(content)
 var shade=ColorRect.new();shade.color=Color("0a1515ba");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.add_child(shade)
 box(content,Rect2(48,29,1184,666),Color("080e0ed9"),Color("786b50"),5);paper(Rect2(58,36,1164,648),Color("eee5cf"))
 heading=text(content,"소지품" if mode=="inventory" else "무공",Rect2(88,53,240,52),38,INK,true)
 text(content,"여정에 필요한 것들을 갖추다" if mode=="inventory" else "실전에 펼칠 네 가지 초식 · 행동력 / 내기 / 범위",Rect2(245,66,500,30),17,MUTED)
 var total=0
 for value in progress.stats.values():total+=int(value)
 text(content,"도원 · "+progress.RULES.realm(total),Rect2(840,64,190,30),18,INK)
 text(content,"◎ %d문" % game.money,Rect2(1040,64,170,30),19,INK)
 line(Rect2(88,113,1104,1));line(Rect2(88,639,1104,1))
 button("소지품  I",Rect2(88,648,122,28),mode=="inventory").pressed.connect(switch_mode.bind("inventory"))
 button("무공  K",Rect2(218,648,112,28),mode=="martial").pressed.connect(switch_mode.bind("martial"))
 var s=progress.stats
 summary=text(content,"근력%d  기민%d  근골%d  내공%d  오성%d  · 명성%d" % [s.strength,s.agility,s.constitution,s.inner,s.insight,progress.fame],Rect2(365,652,655,23),14,MUTED)
 button("ESC 닫기",Rect2(1080,648,116,28)).pressed.connect(close_menu)
 var ids=visible_ids()
 if selected_id!="clear" and selected_id not in ids:selected_id=str(ids[0]) if not ids.is_empty() else ""
 if mode=="inventory":build_inventory(ids)
 else:build_martial(ids)
 if is_instance_valid(list_scroll):list_scroll.set_deferred("scroll_vertical",old_scroll)
 feedback=text(content,message,Rect2(380,612,800,24),14,TEAL)
func scroll_area(rect: Rect2,grid: bool) -> void:
 list_scroll=ScrollContainer.new();list_scroll.position=rect.position;list_scroll.size=rect.size;list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;list_scroll.follow_focus=true;content.add_child(list_scroll)
 if grid:
  var cells=GridContainer.new();cells.columns=3;cells.add_theme_constant_override("h_separation",12);cells.add_theme_constant_override("v_separation",14);rows=cells
 else:
  var list=VBoxContainer.new();list.add_theme_constant_override("separation",9);rows=list
 list_scroll.add_child(rows)
func build_inventory(ids: Array) -> void:
 var portrait=TextureRect.new();portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;content.add_child(portrait);portrait.position=Vector2(88,148);portrait.size=Vector2(245,275)
 var framing=preload("res://scripts/dialogue_portraits.gd").new();framing.apply_framing(portrait,{"portrait":"res://assets/portraits/player/hero.png"});framing.free();portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
 text(content,"도원",Rect2(110,425,200,40),28,INK,true);text(content,"장착 무기",Rect2(110,479,170,25),15,MUTED)
 var equipped=button("",Rect2(104,514,222,87));equipped.pressed.connect(select_equipped)
 icon(equipped,game.battle.equipped_weapon_id,Rect2(6,6,70,70));text(equipped,weapon_name(),Rect2(86,19,130,28),19,INK);text(equipped,"장착 중",Rect2(86,53,125,22),14,MUTED)
 line(Rect2(352,146,1,463));line(Rect2(747,147,1,460))
 for i in range(5):
  var value=["all","weapon","elixir","manual","quest"][i]
  var tab=button(["전체","무기","영약","서적","의뢰"][i],Rect2(377+i*71,143,65,35),false);UI.selection(tab,category==value,true,true);tabs.append(tab);tab.pressed.connect(select_category.bind(value))
 scroll_area(Rect2(379,199,351,348),true)
 for id in ids:
  var cell=button("",Rect2(0,0,103,103));cell.reparent(rows);cell.custom_minimum_size=Vector2(103,103);cell.tooltip_text=item_name(id);cell.set_meta("item_id",id)
  icon(cell,str(id),Rect2(12,10,80,79));selected_style(cell,id==selected_id);UI.item_highlight(cell)
  if id==game.battle.equipped_weapon_id:
   box(cell,Rect2(6,5,72,22),TEAL);text(cell,"장착 중",Rect2(12,5,66,22),13,Color("f5eedb"))
  if id=="none":text(cell,"맨손",Rect2(23,35,80,30),18,INK)
  var count=int(progress.inventory.get(id,0)) if item_kind(id)=="elixir" else int(progress.manuals.get(id,0)) if item_kind(id)=="manual" else 0
  if count>0:
   box(cell,Rect2(62,77,35,21),Color("f4eddb"),LINE);text(cell,"×%d" % count,Rect2(65,77,33,21),14,INK)
  cell.pressed.connect(select_item.bind(str(id)))
 if ids.is_empty():text(rows,"보유한 물품이 없습니다.",Rect2(0,0,330,50),17,MUTED)
 text(content,"물품 선택 후 오른쪽에서 장착·복용합니다.",Rect2(378,565,360,44),14,MUTED)
 detail=rich(Rect2(787,263,373,270));action=button("선택하세요",Rect2(787,558,373,46),true);action.pressed.connect(apply_selection)
 if selected_id.is_empty():action.disabled=true;detail.text="물품을 선택하세요.";return
 var kind=item_kind(selected_id)
 text(content,item_name(selected_id),Rect2(785,154,275,48),29,INK,true)
 text(content,{"weapon":"무기","elixir":"영약","manual":"무공 서적","quest":"의뢰 물품"}.get(kind,""),Rect2(787,205,250,28),16,MUTED)
 icon(content,selected_id,Rect2(1058,157,104,104));update_inventory_detail(kind)
func select_equipped() -> void:category="all";select_item(game.battle.equipped_weapon_id)
func rich(rect: Rect2) -> RichTextLabel:
 var view=RichTextLabel.new();view.position=rect.position;view.size=rect.size;view.add_theme_font_override("normal_font",UI.BODY_FONT);view.add_theme_font_size_override("normal_font_size",17);view.add_theme_color_override("default_color",INK);view.bbcode_enabled=false;view.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(view);return view
func update_inventory_detail(kind: String) -> void:
 var p=progress
 match kind:
  "weapon":
   var item: Dictionary=p.weapons.get_weapon(selected_id)
   detail.text="무기를 해제하면 권법·장법을 사용할 수 있습니다." if selected_id=="none" else str(item.description)+"\n\n공격 보정 +%d%%\n받는 피해 −%d%%\n창법 내기 절감 %d%%" % [item.attack_bonus_percent,item.damage_reduction_percent,item.qi_reduction_percent]
   detail.position=Vector2(787,263);detail.size=Vector2(373,48)
   detail.text="무기를 해제해 맨손으로 전환합니다." if selected_id=="none" else str(item.description)
   line(Rect2(787,314,373,1))
   var selected: Dictionary=p.weapons.get_weapon(selected_id);var current: Dictionary=p.weapons.get_weapon(game.battle.equipped_weapon_id)
   text(content,"공격 보정",Rect2(787,338,200,30),19,INK);text(content,"+%d%%" % selected.get("attack_bonus_percent",0),Rect2(1080,335,90,35),26,TEAL)
   var spear=selected.get("weapon_type","")=="spear"
   text(content,"창법 내기 절감" if spear else "받는 피해",Rect2(787,385,230,30),19,INK)
   text(content,"−%d%%" % selected.get("qi_reduction_percent" if spear else "damage_reduction_percent",0),Rect2(1080,382,90,35),26,TEAL)
   box(content,Rect2(787,444,373,87),Color("e3d8be"))
   text(content,"현재 장비 · "+weapon_name(),Rect2(802,452,350,25),15,MUTED)
   var attack=int(selected.get("attack_bonus_percent",0))-int(current.get("attack_bonus_percent",0))
   var reduction=int(selected.get("damage_reduction_percent",0))-int(current.get("damage_reduction_percent",0))
   var qi=int(selected.get("qi_reduction_percent",0))-int(current.get("qi_reduction_percent",0))
   var comparison=rich(Rect2(802,479,350,47));comparison.add_theme_font_size_override("normal_font_size",15)
   comparison.text="공격 보정 %+.0f%%p · 피해 감소 %+.0f%%p\n창법 내기 절감 %+.0f%%p" % [attack,reduction,qi]
   action.text="맨손으로 전환" if selected_id=="none" else item_name(selected_id)+" 장착";action.disabled=selected_id==game.battle.equipped_weapon_id
   if action.disabled:action.text="장착 중";action.tooltip_text="현재 손에 쥔 병장기입니다."
  "elixir":
   var item: Dictionary=p.elixirs[selected_id];var gains: Dictionary=item.permanent_stat_gains
   detail.text="%s\n\n근력 +%d  기민 +%d\n근골 +%d  내공 +%d\n\n보유 %d개 · 누적 복용 %d/10\n오성 상승 없음" % [item.description,gains.strength,gains.agility,gains.constitution,gains.inner,p.inventory.get(selected_id,0),p.consumed[selected_id]]
   action.text="영약 1개 복용"
   var reason=""
   if int(p.consumed[selected_id])>=int(item.max_lifetime_uses):reason="평생 복용 한도 도달 · 10/10"
   elif int(p.inventory.get(selected_id,0))<=0:reason="보유한 영약이 없습니다."
   else:
    var can_gain=false
    for key in gains:
     if key!="insight" and int(gains[key])>0 and int(p.stats[key])<100:can_gain=true
    if not can_gain:reason="상승할 능력치가 없습니다."
   UI.unavailable(action,reason)
   if not reason.is_empty():detail.add_text("\n! "+reason)
  "manual":
   var item: Dictionary=p.manual_definitions[selected_id]
   detail.text=str(item.description)+"\n\n보유 %d권 · 사용 후 K에서 편성" % p.manuals.get(selected_id,0)
   action.text="서책 1권 사용 · 무공 습득";action.disabled=int(p.manuals.get(selected_id,0))<=0 or item.teaches in p.learned or not p.arts.can_learn(item.teaches,p.stats)
   if not p.arts.can_learn(item.teaches,p.stats):detail.add_text("\n! 학습 조건이 부족합니다.")
   action.tooltip_text="이미 익혔거나 보유 수량·학습 조건을 확인하세요." if action.disabled else ""
   if item.teaches in p.learned:detail.add_text("\n이미 익힌 무공 · 소모하지 않음")
  "quest":detail.text="의뢰 전달 물품입니다. 목표 인물에게 F로 말을 걸어 전달하세요.";action.text="대화로 전달";action.disabled=true
func build_martial(ids: Array) -> void:
 preload("res://scripts/martial_menu_panel.gd").build(self,ids)

func update_detail() -> void:refresh()
func apply_selection() -> void:
 if not is_instance_valid(action) or action.disabled or not visible or game.state!="explore":return
 var ok=false;var kind=item_kind(selected_id)
 match kind:
  "weapon":
   if selected_id=="none" or selected_id in progress.owned_weapons:ok=game.battle.equip_weapon_item(selected_id)
  "elixir":ok=progress.consume(selected_id)
  "manual":ok=progress.use_manual(selected_id)
  "art":ok=progress.assign("" if selected_id=="clear" else selected_id,target_slot);game.battle.set_loadout(progress.loadout)
 message=("무공을 익혔습니다. K에서 편성하세요." if kind=="manual" else "%d번 칸에 편성했습니다." % [target_slot+1] if kind=="art" else item_name(selected_id)+" 장착 완료" if kind=="weapon" else "영약을 복용했습니다.") if ok else progress.error if kind in ["elixir","manual"] else "적용할 수 없습니다."
 if ok and kind=="weapon":game.adventure_ui.notify("장비를 바꾸었습니다.","confirm")
 refresh()
 if ok:UI.applied(feedback)

func focus_selection() -> void:
 if not is_instance_valid(rows):return
 for child in rows.get_children():
  if child is Button and str(child.get_meta("item_id",""))==selected_id:
   child.grab_focus()
   if mode=="martial":_reveal_martial_selection.call_deferred(selected_id)
   return
 if is_instance_valid(action) and not action.disabled:action.grab_focus()
func _reveal_martial_selection(expected: String) -> void:
 await get_tree().process_frame
 if not visible or mode!="martial" or selected_id!=expected or not is_instance_valid(rows) or not is_instance_valid(list_scroll):return
 for child in rows.get_children():
  if child is Control and str(child.get_meta("item_id",""))==expected:
   list_scroll.ensure_control_visible(child);return
func handle_key(event: InputEventKey) -> void:
 var focused=get_viewport().gui_get_focus_owner()
 if not is_instance_valid(focused) or not is_ancestor_of(focused):focus_selection();focused=get_viewport().gui_get_focus_owner()
 if not is_instance_valid(focused):return
 if event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
  if focused is Button and not focused.disabled:focused.pressed.emit()
  return
 var next: Control
 if event.keycode==KEY_TAB:next=focused.find_prev_valid_focus() if event.shift_pressed else focused.find_next_valid_focus()
 elif event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:next=focused.find_valid_focus_neighbor({KEY_LEFT:SIDE_LEFT,KEY_RIGHT:SIDE_RIGHT,KEY_UP:SIDE_TOP,KEY_DOWN:SIDE_BOTTOM}[event.keycode])
 if is_instance_valid(next) and is_ancestor_of(next):next.grab_focus()
