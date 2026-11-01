extends "res://scripts/city_service.gd"
## Reuses the actual service screen, icons, framing and purchase validator.
## Only the host's isolated PlayerProgress/money can be changed here.
const ITEM="bear_strength_pill"
var owner_trial
var last_purchase_frame=-1
func _ready() -> void:
 super._ready();process_mode=Node.PROCESS_MODE_ALWAYS
 for tab in tabs:tab.hide()
 for slot in slots:slot.hide()
func open_counter(_definition: Dictionary) -> void:
 service={"id":"TownMerchant","kind":"market","name":"약재 행상"};selected_id=ITEM
 heading.text="약재 행상 · 웅력환"
 owner_trial.world.dialogue.dialogue_cast.apply_framing(portrait,{"basic_portrait":"male_common_b"})
 feedback.text="";refresh_list();update_detail();show();action.grab_focus()
func select_tab(_index: int) -> void:pass
func refresh_list() -> void:
 for child in rows.get_children():child.queue_free()
 var item: Dictionary=owner_trial.progress.elixirs[ITEM]
 var button=UI.button(rows,"%s · %d문" % [item.name,item.price],Rect2(0,0,365,50));button.custom_minimum_size=Vector2(365,50)
 Icons.apply(button,ITEM);button.pressed.connect(select_item.bind(ITEM))
func select_item(id: String) -> void:
 if id!=ITEM:return
 selected_id=id;feedback.text="";update_detail()
func update_detail() -> void:
 var p=owner_trial.progress;var item: Dictionary=p.elixirs[ITEM];var price=int(item.price)
 summary.text="소지금 %d문 · 웅력환 보유 %d개" % [owner_trial.money,p.inventory[ITEM]]
 balance_preview.text="구매 후 %d문" % (owner_trial.money-price) if owner_trial.money>=price else "소지금이 부족합니다"
 message.text=item.name+"\n\n"+item.description+"\n\n보유 %d개 · 한 개 %d문" % [p.inventory[ITEM],price]
 action.text="%d문 · 한 개 구매" % price
 var problem: String=p.issue("elixir",ITEM,owner_trial.money);UI.unavailable(action,problem);action.disabled=not problem.is_empty()
func transact() -> void:
 if not visible or service.is_empty() or selected_id!=ITEM:return
 var frame=Engine.get_process_frames()
 if frame==last_purchase_frame:return
 last_purchase_frame=frame
 var ok: bool=owner_trial.progress.purchase("elixir",ITEM,owner_trial)
 feedback.text="웅력환 한 개를 받았습니다." if ok else owner_trial.progress.error
 update_detail()
func _input(event: InputEvent) -> void:
 if not visible:return
 if event is InputEventKey:
  if event.pressed and not event.echo and event.keycode==KEY_ESCAPE:close_counter()
  get_viewport().set_input_as_handled()

func close_counter() -> void:
 if not visible:return
 super.close_counter()
