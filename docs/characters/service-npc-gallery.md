# 도시 상인·장인·교관의 기본 이미지

사용자 확정: 앞으로 모든 도시에 아래3직업을 배치하고, 직업별2종 중1종을 선택한다. 선택한 그림은 해당 NPC의 대화와 거래창에 함께 적용한다. 현재 장사는A, 무창은B를 사용한다. 도시별 인물의 이름·설정은 별도로 부여하며 그림을 재사용한다.

|직업|기본A · 장사형|기본B · 무창형|
|---|---|---|
| **상인** | **장사 상인형**<br>[![장사 상인형](../../godot/assets/portraits/services/merchant.png)](../../godot/assets/portraits/services/merchant.png)<br>`merchant_a` | **유백초형**<br>[![유백초형](../../godot/assets/portraits/wuchang/liu_baicao.png)](../../godot/assets/portraits/wuchang/liu_baicao.png)<br>`merchant_b` |
| **장인** | **장사 장인형**<br>[![장사 장인형](../../godot/assets/portraits/services/artisan.png)](../../godot/assets/portraits/services/artisan.png)<br>`artisan_a` | **석대용형**<br>[![석대용형](../../godot/assets/portraits/wuchang/shi_dayong.png)](../../godot/assets/portraits/wuchang/shi_dayong.png)<br>`artisan_b` |
| **교관** | **장사 교관형**<br>[![장사 교관형](../../godot/assets/portraits/services/instructor.png)](../../godot/assets/portraits/services/instructor.png)<br>`instructor_a` | **임정산형**<br>[![임정산형](../../godot/assets/portraits/wuchang/lin_zhengshan.png)](../../godot/assets/portraits/wuchang/lin_zhengshan.png)<br>`instructor_b` |

기존 그림6종을 직업별로 지정한 것이며 새로운 이미지를 만들지 않았다. 일반 주민 기본18장 목록은 그대로 유지한다. 후보/현재 배정의 원본은 [직업 이미지 데이터](../../godot/data/service_npc_portraits.json), 상세 규칙은 [인물 제작 원칙](creation-guidelines.md)을 따른다. 이 데이터는 도시 제작용 공용 목록이며 현재 런타임에서 그림을 무작위로 교체하지 않는다.
