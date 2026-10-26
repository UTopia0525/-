extends Control
## Shared journal/help/preferences/log shell. Menu pausing is independent of story state.
const UI=preload("res://scripts/ui.gd")
const HELP=[
["길과 인물","WASD / 방향키로 이동합니다. 맵의 인물·사물은 가까이에서 F로 상호작용하며, 마우스는 메뉴 선택에 사용합니다. 가까운 대화 대상의 발밑에 금색 표시가 생깁니다. F는 대화·거래·조사 키입니다. 건물과 담장을 돌아가고 열린 문의 가운데를 통과하세요."],
["세력 호의도 · R","R로 세력 호의도 창을 엽니다. 호의도를 얻은 세력부터 목록에 나타나며, 현재 수치를 최대100인 막대로 보여 줍니다. R 또는 ESC로 닫습니다."],
["의뢰 · Q","Q로 의뢰 일지를 엽니다. 진행 중·수락 가능·완료를 나누어 볼 수 있습니다. 노란 !는 의뢰를 줄 인물, 노란 ?는 달성을 마치고 보고를 기다리는 인물입니다. 조건만 채워서는 보상을 받지 못하며 완료 대화를 마쳐야 합니다. 일반 의뢰는 서로 독립적입니다."],
["지도와 시설","TAB으로 전체 지도를 엽니다. 약=영약 상인, 장=무기 장인, 무=무공 교관입니다. 시설 안내 버튼을 누르면 미니맵이 해당 인물을 가리킵니다. 의뢰 일지에서 다시 의뢰를 추적하면 시설 안내가 끝납니다."],
["거래와 소지품 · I","시설 앞에서 F로 대화하면 거래합니다. 물건을 선택해 현재 장비와 비교하고 구매 후 남을 돈을 확인하세요. 구매만으로 장착·복용되지는 않습니다. I 소지품에서 무기를 장착하고 영약을 복용하세요. 같은 영약은 평생 10개까지, 오성은 영약으로 오르지 않습니다."],
["무공과 편성 · K","K에서 익힌 무공과 실전에 쓸 네 칸을 정합니다. 기본공격·기본방어도 바꿀 수 있습니다. 검법·도법·창법은 해당 무기가, 권법·장법은 맨손이 필요합니다. 교관에게 배울 때 부족한 능력치와 합계를 확인하세요."],
["실전의 죽음","주요 실전에서 패배하면 도원이 사망합니다. 종료 화면에서 F/Enter 또는 버튼을 눌러 처음 화면으로 돌아간 뒤 이전 저장을 불러올 수 있습니다. 전투 전에 진행을 저장하세요. 대련과 기존 재도전 전투는 별도 규칙을 따릅니다."],
["교전과 기록 · L","무공 선택 후 사용을 눌러 실행합니다. 선택만으로 턴은 지나지 않습니다. 기본방어는 다음 적 행동의 피해 20%를 줄입니다. 검법은 사용 후 다음 적 행동 피해를 20% 줄이며 중첩하지 않습니다. 적의 예고는 기세만 알려 줍니다. L 교전 기록은 이미 실행된 기술과 피해·내기만 보여 줍니다."],
["성장과 내기","근력·기민·근골·내공·오성은 각 0~100입니다. 합계 100/200/300/400/500에서 절정/초절정/화경/현경/자연경이 됩니다. 매 전투 체력은 300, 내기는 내공만큼으로 시작하며 교전 후 살아 있으면 내공만큼 회복합니다. 내기 상한은 500입니다."],
["대화·저장·설정","대화 중 H는 지금까지 읽은 대사 기록입니다. 미래 대사나 미선택 분기는 보여 주지 않습니다. ESC 설정에서 탐험·분기 선택창을 저장할 수 있습니다. 대화·거래·전투 중 새 저장은 불가합니다. 환경 설정에서 BGM/효과음 음량·화면 모드·대화와 도움말 글자 크기를 바꿉니다. F2로 도움말을 다시 엽니다."]]
var game
var window: Control
var panel: Panel
var heading: Label
var rows: VBoxContainer
var body: RichTextLabel
var primary: Button
var secondary: Button
var filter_buttons: Array[Button]=[]
var options_box: VBoxContainer
var toast: Label
var toast_tween: Tween
var mode:=""
var filter:="active"
var selected:=""
var entries: Dictionary={}
var pending_toasts: Array[String]=[]
var notifications: Array[String]=[]
var results: Array[Dictionary]=[]
var prior_pause:=false
var return_settings:=false
var first_choice: Callable
var second_choice: Callable
var facility_filter:="all"

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);z_index=80
	window=Control.new();window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);window.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(window)
	var shade=ColorRect.new();shade.color=Color("07110bef");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);window.add_child(shade)
	panel=UI.panel(window,Rect2(80,35,1120,650));panel.mouse_filter=Control.MOUSE_FILTER_STOP
	heading=UI.label(panel,"",Rect2(26,15,1030,40),28,UI.GOLD)
	for i in range(3):
		var button=UI.button(panel,["진행 중","수락 가능","완료"][i],Rect2(26+i*110,70,105,36))
		button.add_theme_font_size_override("font_size",15)
		button.pressed.connect(set_filter.bind(["active","available","completed"][i]));filter_buttons.append(button)
	var scroll=ScrollContainer.new();scroll.position=Vector2(26,122);scroll.size=Vector2(325,425);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
	rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(rows)
	body=RichTextLabel.new();body.position=Vector2(380,80);body.size=Vector2(710,460);body.bbcode_enabled=false;body.selection_enabled=true;body.focus_mode=Control.FOCUS_ALL
	body.add_theme_font_override("normal_font",UI.BODY_FONT);body.add_theme_stylebox_override("focus",StyleBoxEmpty.new());body.add_theme_color_override("default_color",UI.TEXT);panel.add_child(body)
	primary=UI.button(panel,"",Rect2(380,556,340,44),true);primary.pressed.connect(primary_action)
	secondary=UI.button(panel,"",Rect2(740,556,350,44));secondary.pressed.connect(secondary_action)
	var close=UI.button(panel,"닫기 · ESC",Rect2(26,556,325,44));close.pressed.connect(close_menu)
	options_box=VBoxContainer.new();options_box.position=Vector2(390,120);options_box.size=Vector2(680,350);options_box.add_theme_constant_override("separation",16);panel.add_child(options_box)
	toast=UI.label(self,"",Rect2(300,590,490,80),17,UI.GOLD);toast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast.z_index=-1
	toast.add_theme_stylebox_override("normal",UI.box(Color("112017f5")));toast.hide();window.hide();apply_font()
func apply_font() -> void:
	if is_instance_valid(body):body.add_theme_font_size_override("normal_font_size",game.options.body_size if is_instance_valid(game.options) else 21)
func can_open() -> bool:
	return game.state!="title" and not game.settings_menu.window.visible and not game.dialogue_history.visible
func open_journal() -> void:
	if window.visible:
		if mode=="journal":close_menu()
		return
	if game.state!="explore" or not game.dialogue_lines.is_empty() or game.city_service.visible or game.city_overview.visible or not can_open():return
	game.player_menu.close_menu();open_shell("journal");set_filter("active")
func open_favor() -> void:
	if window.visible:
		if mode=="favor":close_menu()
		return
	if game.state!="explore" or not game.dialogue_lines.is_empty() or game.city_service.visible or game.city_overview.visible or not can_open():return
	game.player_menu.close_menu();open_shell("favor")
	heading.text="세력 호의도 · R";primary.hide();secondary.hide()
	body.text="아직 인연을 쌓은 세력이 없습니다." if game.progress.known_factions.is_empty() else "강호에서 쌓은 인연을 살펴봅니다.\n\n세력마다 호의도가 따로 쌓이며, 최대100입니다."
	for faction in game.progress.known_factions:
		var value: int=game.progress.favor_for(faction)
		var box=VBoxContainer.new();rows.add_child(box)
		var label=UI.label(box,"%s  %d / 100" % [game.progress.FACTIONS[faction],value],Rect2(0,0,310,38),20,UI.GOLD)
		label.custom_minimum_size=Vector2(310,38)
		var bar=ProgressBar.new();bar.min_value=0;bar.max_value=game.progress.FAVOR_MAX;bar.value=value;bar.show_percentage=false;bar.custom_minimum_size=Vector2(310,20);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var background=StyleBoxFlat.new();background.bg_color=Color("112017")
		var fill=StyleBoxFlat.new();fill.bg_color=Color("b89554")
		bar.add_theme_stylebox_override("background",background)
		bar.add_theme_stylebox_override("fill",fill)
		box.add_child(bar)
func open_shell(kind: String,pause_world: bool=true) -> void:
	if window.visible:
		return_settings=false
		close_menu()
	mode=kind;prior_pause=get_tree().paused;game.exploration.player.stop()
	if pause_world:get_tree().paused=true
	window.show();options_box.hide();body.show();primary.show();secondary.hide()
	for button in filter_buttons:button.visible=kind=="journal"
	clear_rows();selected="";body.clear();primary.disabled=false;return_settings=false
	body.grab_focus()
	game.options.play("confirm")
func close_menu() -> void:
	if not window.visible:return
	window.hide();get_tree().paused=prior_pause;first_choice=Callable();second_choice=Callable()
	var back:=return_settings;return_settings=false
	if back:game.settings_menu.open_menu()
func dismiss() -> void:
	return_settings=false;close_menu()
func reset() -> void:
	dismiss();results.clear();notifications.clear();pending_toasts.clear();toast.hide()
	if toast_tween and toast_tween.is_valid():toast_tween.kill()
func clear_rows() -> void:
	for child in rows.get_children():rows.remove_child(child);child.queue_free()
func row(text: String,callback: Callable) -> void:
	var button=UI.button(rows,text,Rect2(0,0,310,52));button.custom_minimum_size=Vector2(310,52);button.add_theme_font_size_override("font_size",16);button.pressed.connect(callback);button.pressed.connect(func():game.options.play("confirm"))
func set_filter(value: String) -> void:
	filter=value;selected="";heading.text="의뢰 일지 · Q";clear_rows();entries.clear();body.text="의뢰를 골라 현재 용건과 품삯을 확인하세요.";primary.text="이 의뢰 추적";primary.disabled=true
	for i in range(3):filter_buttons[i].disabled=["active","available","completed"][i]==filter
	var prologue_state: String="completed" if game.prologue.completed else "active"
	if (game.prologue.active or game.prologue.completed) and filter==prologue_state:
		entries["prologue_record"]={"status":prologue_state}
		row("0장 · 표행의 기록",select_quest.bind("prologue_record"))
	for id in game.trade_intro.IDS:
		var record: Dictionary=game.chapter_one.accepted_quests.get(id,{})
		if record.is_empty():continue
		var state: String="completed" if record.status=="completed" else "active"
		if state==filter:add_quest_row(id,state,record.stage,"도입 연계")
	for id in game.ordinary_quests.definitions:
		var state: String=game.ordinary_quests.status(id)
		if (filter=="active" and state in ["active","ready"]) or filter==state:add_quest_row(id,state,"offer" if state=="available" else game.ordinary_quests.stage_for(id),"장사 · 일반 의뢰")
	for quest in game.regional_quests():
		var quest_status: String=quest.status()
		if (filter=="active" and quest_status in ["active","ready"]) or filter==quest_status:
			add_quest_row(quest.ID,quest_status,quest.stage(),"메인 이야기" if quest.ID==game.alliance_story.ID else "남경 · 일반 의뢰" if quest.ID==game.silk_quest.ID else "남경 · 구휼 사건" if quest.ID==game.nanjing_relief_quest.ID else "산촌 · 일반 의뢰" if quest.ID==game.qingya_quest.ID else "무창 · 일반 의뢰")
	var story=game.bandit_story
	if story.stage!="dormant":
		var state: String="completed" if story.stage=="completed" else "active"
		if state==filter:add_quest_row(story.QUEST_ID,state,{"offered":"enlist","report":"report"}.get(story.stage,"muster"),"주요 이야기")
	if entries.is_empty():body.text={"active":"진행 중인 의뢰가 없습니다.\n수락 가능 목록을 살피거나 시설에서 강호행을 준비하세요.","available":"지금 받을 수 있는 일반 의뢰가 없습니다.\n진행 중인 용건과 성장·정비를 살펴보세요.","completed":"아직 마친 의뢰가 없습니다.\n노란 ! 인물에게 일거리를 물어보세요."}[filter]
func add_quest_row(id: String,state: String,stage: String,kind: String) -> void:
	entries[id]={"status":state,"stage":stage,"kind":kind}
	row(("◆ " if game.quest_navigation.quest_id==id else "")+("? " if state=="ready" else "! " if state=="available" else "")+game.quest_navigation.definitions[id].title,select_quest.bind(id))
func select_quest(id: String) -> void:
	if id=="prologue_record":
		selected=id;primary.disabled=true;primary.text="이야기의 목표 안내를 따르세요"
		var history: String="현재 할 일: "+game.objective.text+"\n\n보수는 표행의 결과에 따라 이야기에서 확인됩니다."
		if game.prologue.completed:history="귀물을 전달하고 인도 보수 3,000문을 받았다." if game.prologue.branch=="treasure" else "사람을 구하고 귀물을 잃었다. 인도 보수는 받지 않았다."
		body.text="0장 · 표행의 기록\n\n"+history
		return
	selected=id;var data: Dictionary=entries[id];var nav: Dictionary=game.quest_navigation.definitions[id]
	var reward: String="500문 · 오성+2 · 명성+5 (귀환 보고 후)" if id==game.bandit_story.QUEST_ID else "%d문 · 오성+2 (상한100)" % int(game.trade_intro.rewards.quests.get(id,{"money":0}).money)
	for quest in game.regional_quests():
		if id==quest.ID:reward=quest.reward_label().trim_prefix("보수 ")
	var who: String="연계 대화에서 받은 용건"
	for quest in game.regional_quests():
		if id==quest.ID:who=game.PORTRAITS.ACTORS[quest.GIVER].name
	if game.ordinary_quests.definitions.has(id):who=game.PORTRAITS.ACTORS[game.ordinary_quests.definitions[id].giver].name
	body.text="%s\n%s · %s\n\n의뢰인: %s\n\n%s\n\n보수: %s\n\n%s" % [nav.title,data.kind,{"active":"진행 중","available":"수락 가능","ready":"달성 · 완료 보고 대기","completed":"완료"}[data.status],who,"이미 마친 의뢰입니다." if data.status=="completed" else nav.stages[data.stage].label,reward,"보수를 받았습니다." if data.status=="completed" else "일지에서 수락하지 않습니다. 의뢰인에게 F로 말을 걸어 직접 맡으세요." if data.status=="available" else "보상을 받으려면 완료 대화를 끝내야 합니다."]
	if game.ordinary_quests.records.has(id):body.add_text("\n\n현재 달성 %d/%d" % [game.ordinary_quests.records[id].done.size(),game.ordinary_quests.definitions[id].steps.size()])
	for quest in game.regional_quests():
		if id==quest.ID and quest.has_method("journal_items"):
			for item in quest.journal_items():
				body.add_text("\n\n"+str(item.name)+"\n")
				body.add_image(preload("res://scripts/catalog_icons.gd").texture(item.id),64,64)
	primary.disabled=data.status=="completed"
	primary.text="의뢰인 위치 안내" if data.status=="available" else "이 의뢰 추적"
func primary_action() -> void:
	match mode:
		"journal":
			if not selected.is_empty() and not primary.disabled:
				game.quest_navigation.track(selected,entries[selected].stage,game.ordinary_quests.records.get(selected,{}).get("done",[]));notify("의뢰 추적 · "+game.quest_navigation.definitions[selected].title,"confirm");close_menu()
		"choice":
			var callback:=first_choice
			close_menu()
			if callback.is_valid():callback.call()
		"teaching":
			if not primary.disabled:game.alliance_story.confirm_art(selected)
		"options":open_help(true)
		_:close_menu()
func secondary_action() -> void:
	if mode=="choice":
		var callback:=second_choice
		close_menu()
		if callback.is_valid():callback.call()
func choose(title: String,text: String,a: String,yes: Callable,b: String,no: Callable) -> void:
	open_shell("choice");heading.text=title;body.text=text+"\n\n1 / 2 또는 버튼으로 선택합니다.";primary.text=a;secondary.text=b;secondary.show();first_choice=yes;second_choice=no;primary.grab_focus()
func open_teaching() -> void:
	open_shell("teaching");heading.text="곽진석 · 중급 무공 전수"
	primary.text="이 무공 선택";primary.disabled=true
	body.text="다섯 길 가운데 한 문을 전수받습니다.\n목록에서 무공을 골라 살펴보세요.\n\n학습 능력치 제한은 없습니다. 실전에는 해당 무기와 내기가 필요합니다.\nK에서 전투 초식을 편성하고 I에서 무기를 갖추세요."
	for id in game.alliance_story.ARTS:
		var art: Dictionary=game.progress.arts.get_skill(id)
		row(str(art.name)+( " · 이미 익힘" if id in game.progress.learned else ""),select_teaching.bind(id))
		preload("res://scripts/catalog_icons.gd").apply(rows.get_child(-1),id)
func select_teaching(id: String) -> void:
	if mode!="teaching" or id not in game.alliance_story.ARTS:return
	selected=id
	var art: Dictionary=game.progress.arts.get_skill(id)
	body.text="%s\n\n%s\n\n%s\n기본 내기 소모: %d\n현재 능력치 기준 위력: %d (무기·상대 방어 보정 전)\n\n이번 방문에서는 한 문만 전수받습니다.\n학습 능력치 제한은 없습니다. 습득 뒤 K에서 편성하세요." % [art.name,art.description,game.progress.arts.weapon_requirement(id),art.qi_cost,int(game.progress.arts.raw_damage(id,game.progress.stats))]
	primary.disabled=id in game.progress.learned;primary.text="이미 익힌 무공" if primary.disabled else "이 무공 선택"
func open_help(from_settings: bool=false) -> void:
	if game.dialogue_history.visible:return
	if game.player_menu.visible:game.player_menu.close_menu()
	open_shell("help");return_settings=from_settings;heading.text="강호 길잡이 · F2";primary.text="돌아가기"
	for i in range(HELP.size()):row(HELP[i][0],help_topic.bind(i))
	help_topic(0)
func help_topic(index: int) -> void:body.text=HELP[index][0]+"\n\n"+HELP[index][1]
func open_options() -> void:
	game.settings_menu.close_menu();open_shell("options");return_settings=true;heading.text="환경 설정";body.hide();options_box.show();primary.text="조작 도움말"
	for child in options_box.get_children():options_box.remove_child(child);child.queue_free()
	for spec in [["BGM 음량","bgm",game.options.bgm_volume],["효과음 음량","sfx",game.options.sfx_volume]]:
		var label=Label.new();label.text=spec[0]+" · %d%%" % int(spec[2]);options_box.add_child(label)
		var slider=HSlider.new();slider.min_value=0;slider.max_value=100;slider.step=5;slider.value=spec[2];slider.custom_minimum_size=Vector2(650,30);options_box.add_child(slider)
		slider.value_changed.connect(func(value):label.text=spec[0]+" · %d%%" % int(value);game.options.update(spec[1],value))
	var size_label=Label.new();size_label.text="대화·도움말·기록 글자 크기";options_box.add_child(size_label)
	var sizes=OptionButton.new()
	for text in ["작게 · 18","보통 · 21","크게 · 24"]:sizes.add_item(text)
	sizes.select([18,21,24].find(game.options.body_size));sizes.item_selected.connect(func(index):game.options.update("size",index));options_box.add_child(sizes)
	var full=CheckButton.new();full.text="전체 화면";full.button_pressed=game.options.fullscreen;full.toggled.connect(func(value):game.options.update("fullscreen",value));options_box.add_child(full)
	row("저장과 불러오기",close_menu);row("조작 도움말",open_help.bind(true))
func notify(text: String,sound: String="confirm") -> void:
	notifications.append(text)
	if notifications.size()>50:notifications.pop_front()
	game.options.play(sound)
	pending_toasts.append(text)
	if pending_toasts.size()>8:pending_toasts.pop_front()
	if not toast.visible:_show_next_toast()
func _show_next_toast() -> void:
	if pending_toasts.is_empty():toast.hide();return
	toast.text=pending_toasts.pop_front();toast.modulate.a=1;toast.show()
	toast_tween=create_tween();toast_tween.tween_interval(3);toast_tween.tween_property(toast,"modulate:a",0,.4);toast_tween.tween_callback(_show_next_toast)
func tip(id: String,text: String) -> void:
	if id in game.options.seen:return
	game.options.seen.append(id);game.options.persist();notify(text+"\nF2 도움말에서 다시 볼 수 있습니다.","confirm")
func record_result(won: bool,show_summary: bool=true) -> void:
	results.append({"won":won,"enemy":game.battle.enemy_name.text,"turns":game.battle.turn,"events":game.battle.records.duplicate(true),"player_hp":game.battle.player_hp})
	if results.size()>10:results.pop_front()
	if show_summary:open_log(true)
func open_log(automatic: bool=false) -> void:
	if game.settings_menu.window.visible or game.dialogue_history.visible:return
	open_shell("result" if automatic else "log",not automatic);heading.text="교전 기록 · L";primary.text="이야기로 돌아가기" if automatic else "닫기"
	if game.state=="battle" and game.battle.running and not automatic:render_events(game.battle.records,"현재 교전 · 실행된 행동만 표시합니다.")
	elif not results.is_empty():select_result(results.size()-1)
	else:body.text="아직 교전 기록이 없습니다."
	for i in range(results.size()):row(("승리 · " if results[i].won else "패배 · ")+str(results[i].enemy),select_result.bind(i))
func select_result(index: int) -> void:
	var result: Dictionary=results[index]
	var note: String="승리 · %s · %d교전\n남은 체력 %d/300\n이 교전에서 즉시 받는 보상: 없음.
표행·의뢰 보수는 해당 이야기의 인도·보고 후 지급합니다.\n다음 전투는 체력과 시작 내기를 새로 갖춥니다." % [result.enemy,result.turns,result.player_hp] if result.won else "패배 · %s\n산적 토벌은 퇴각 대화를 마친 뒤 I/K로 정비하고 동문에서 다시 출정할 수 있습니다.\n0장/전투 체험은 전투창의 다시 도전으로 재개합니다." % result.enemy
	if not result.won and result.enemy=="구칠":note="패배 · 구칠\n약초 꾸러미가 있던 곳으로 물러났습니다. 조사 진도는 유지됩니다.\nI/K에서 정비한 뒤 약초꾼이 있는 곳에서 F로 다시 도전하세요.\n다음 전투는 체력과 시작 내기를 새로 갖춥니다."
	if result.enemy=="유소강":note=("승리" if result.won else "패배")+" · 연무장 대련\n대련을 마쳤습니다. 임정산에게 보고하면 승패와 관계없이 조식수원공을 전수받습니다."
	if result.enemy=="마응칠":note="승리 · 육정호에게 보고한 뒤 송지겸의 감사를 받으세요." if result.won else "패배 · 조사 진도는 유지됩니다. I/K에서 정비 후 나루 창고 뒤에서 다시 도전하세요."
	if result.enemy=="장만길":note=("승리 · 도삼랑에게 해결 결과를 보고하세요. 보수는 보고 후150문입니다." if result.won else "패배 · 비무를 중단했습니다. 말로 중재하거나 I/K에서 정비 후 다시 도전할 수 있습니다. 아직 보수는 지급되지 않았습니다.")
	render_events(result.events,note)
func render_events(events: Array,note: String) -> void:
	body.text=note+"\n\n"
	for event in events:
		if event.kind=="recovery":body.add_text("%d교전 · %s 내기 +%d · 현재 %d\n" % [event.turn,event.actor,-event.cost,event.qi])
		else:body.add_text("%d교전 · %s · %s\n피해 %d · 내기 소모 %d · 잔여 %d · 초식 방어 %d%%\n\n" % [event.turn,event.actor,event.technique,event.damage,event.cost,event.qi,event.guard])
func _focusable(node: Node,result: Array[Control]) -> void:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree() and child.focus_mode==Control.FOCUS_ALL and (not child is BaseButton or not child.disabled):result.append(child)
		_focusable(child,result)
func _cycle_focus(backwards: bool) -> void:
	var controls: Array[Control]=[];_focusable(window,controls)
	if controls.is_empty():return
	var index:=controls.find(get_viewport().gui_get_focus_owner())
	controls[posmod(index+(-1 if backwards else 1),controls.size())].grab_focus()
func _input(event: InputEvent) -> void:
	if not window.visible or not event is InputEventKey or not event.pressed or event.echo:return
	var focused=get_viewport().gui_get_focus_owner()
	if not is_instance_valid(focused) or not window.is_ancestor_of(focused):
		if body.visible:body.grab_focus()
		else:primary.grab_focus()
		focused=get_viewport().gui_get_focus_owner()
	if event.keycode==KEY_TAB:
		_cycle_focus(event.shift_pressed);get_viewport().set_input_as_handled();return
	if event.keycode in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT] and not focused is RichTextLabel and not (focused is HSlider and event.keycode in [KEY_LEFT,KEY_RIGHT]):
		_cycle_focus(event.keycode in [KEY_UP,KEY_LEFT]);get_viewport().set_input_as_handled();return
	var handled:=true
	if mode=="choice" and event.keycode==KEY_1:primary_action()
	elif mode=="choice" and event.keycode==KEY_2:secondary_action()
	elif mode=="choice" and event.keycode==KEY_ESCAPE:
		if heading.text.begins_with("의뢰"):secondary_action()
		else:close_menu()
	elif event.keycode==KEY_ESCAPE or (mode=="journal" and event.keycode==KEY_Q) or (mode=="favor" and event.keycode==KEY_R) or (mode=="help" and event.keycode==KEY_F2) or (mode in ["result","log"] and (event.is_action_pressed("interact") or event.keycode in [KEY_L,KEY_ENTER])):close_menu()
	else:handled=false
	if handled:get_viewport().set_input_as_handled()
