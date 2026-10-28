extends Control
## Optional, event-driven prologue guidance. Never changes combat resources or rules.
const UI=preload("res://scripts/ui.gd")
const KEY="prologue_grid_lesson_v1"
const STEPS=[
 ["출수의 때를 살펴라","왼쪽 위 행동력을 보세요.\n행동력100 이상에서 행동할 수 있고, 행동마다 비용이 다릅니다.\n기민이 높을수록 기회가 빨리 옵니다.","안내를 읽고 다음으로"],
 ["먼저 간격을 좁혀라","WASD / 방향키로 한 칸 이동해 보세요.\n이동에는 행동력20을 씁니다.\n이동 후에도100 이상이면 이어서 행동할 수 있습니다.","직접 한 칸 이동하세요"],
 ["펼칠 초식을 골라라","오른쪽 아래 삼재검법을 누르거나 편성 번호3을 누르세요.\n선택만으로는 비용이 들지 않습니다.\n왼쪽 아래 그림은 기술의 범위와 효과입니다.","삼재검법을 선택하세요"],
 ["검끝이 닿는 곳을 보라","붉은 칸이 공격 범위입니다.\n범위 밖이면 먼저 다가가세요. R로 공격 방향을 돌릴 수 있습니다.\n상대가 범위 안에 들면 Enter / Space / 출수 버튼으로 펼치세요.","삼재검법을 한 번 펼치세요"],
 ["공수의 호흡을 익혀라","기본방어를 선택하고 펼쳐 보세요.\n다음 자기 행동 시작까지 그사이 받는 공격 피해를20% 줄입니다.\n매 자기 행동이 끝나면 내공만큼 내기가 회복됩니다.","기본방어를 한 번 펼치세요"],
 ["내기를 아껴 견제하라","기본공격은 내기를 쓰지 않습니다.\n첫 편성 칸 또는 B로 선택한 뒤 펼치세요.\n행동력30을 쓰고 위력은 근력+내공입니다.","기본공격을 한 번 펼치세요"],
 ["이제 그대의 판단이다","무공은 행동력과 내기를 함께 살펴 쓰세요.\n남은 수적을 물리치면 이야기가 이어집니다.\nL은 교전 기록, F2는 도움말입니다. 전투 중에는 저장할 수 없습니다.","기본 수련을 마쳤습니다"]]
var game
var active=false
var step=0
var title: Label
var body: Label
var objective: Label
var next: Button
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var panel=UI.panel(self,Rect2(16,169,250,306))
 title=UI.label(panel,"",Rect2(14,10,222,28),20,UI.GOLD)
 body=UI.label(panel,"",Rect2(14,47,222,161),15,UI.TEXT);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 objective=UI.label(panel,"",Rect2(14,211,222,29),12,UI.GOLD);objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 next=UI.button(panel,"다음",Rect2(14,246,105,29),true);next.pressed.connect(advance)
 var skip=UI.button(panel,"안내 닫기",Rect2(129,246,107,29));skip.pressed.connect(finish)
 for button in [next,skip]:button.add_theme_font_size_override("font_size",13);button.focus_mode=Control.FOCUS_NONE
 hide()
func start(owner_game) -> void:
 game=owner_game;active=false;hide()
 if not game.prologue.active or not game.battle.encounter.is_empty() or KEY in game.options.seen:return
 active=true;step=0;show();refresh()
func refresh() -> void:
 title.text="수련 %d/%d · %s" % [step+1,STEPS.size(),STEPS[step][0]]
 title.add_theme_font_size_override("font_size",16)
 body.text=STEPS[step][1];objective.text=STEPS[step][2]
 next.text="마치기" if step==6 else "다음" if step==0 else "넘기기"
func advance() -> void:
 if not active:return
 if step==6:finish();return
 step+=1;refresh()
func selection(id: String) -> void:
 if active and step==2 and id=="samjae":advance()
func action_done(id: String) -> void:
 if not active:return
 if (step==1 and id=="move") or (step==3 and id=="samjae") or (step==4 and id=="basic_defense") or (step==5 and id=="basic_attack"):advance()
func finish() -> void:
 if active and is_instance_valid(game):
  if KEY not in game.options.seen:game.options.seen.append(KEY);game.options.persist()
 active=false;hide()
func stop() -> void:
 active=false;hide()
