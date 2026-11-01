extends "res://scripts/quest_navigation.gd"
func _ready() -> void:
 # Only this instance's definitions exist; no main-game registrations or callbacks.
 definitions={"iso_errand":{"title":"민가에 두고 온 연장","stages":{"inspect":{"label":"민가 탁자의 대패 확인","goals":[]},"report":{"label":"문길 짐꾼에게 보고","goals":[]},"completed":{"label":"확인 의뢰 완료","goals":[]}}}}
