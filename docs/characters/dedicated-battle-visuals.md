# 고유 인물의 전투 도트

사용자 확정 범위는 현재 전투에 참여하는 마운표·모용유안·탁문호와 지원자 남궁서진이다. 아직 싸우지 않는 고유 인물의 전투 자산은 실제 전투를 추가할 때 제작한다.

| 인물 | 전투 연결 ID | 외형과 연출 |
| --- | --- | --- |
| 모용유안 | `mr_heir` / `mr_exchange` | 자주색·백색 검복, 옥/은 장식, 가는 연보랏빛 검 궤적과 피격 파편 |
| 탁문호 | `cy_tak` / `cuiyue_tak` | 검은 금테 무복, 붉은 갈색 띠, 흉터·수염, 넓은 도의 동빛 궤적과 피격 섬광 |
| 마운표 | `qy_ma_yunpiao` / `qingya_maunpyo` | 근육질·해진 녹색 무복·맨손, 주먹 충격환/먼지와 피격 충격선 |
| 남궁서진 | `namgung_seojin` / 지원 | 흰색·밝은 청색 구름무늬, 옥 장식, 청백색 검 궤적과 피격 섬광 |

각 인물은 독립 PNG와 대기·공격 준비·출수·피격4자세를 갖는다. 도원은 기존 시트와 청색 복식 보정을 유지하고 일반 적은 기존 공용 무기별16자세를 유지한다. 수치·무공·판정·승패·보상은 변경하지 않았다.

## 미술과 표시 기준

기존 도원 전투 시트의 선명한 픽셀 윤곽/덩어리 명암/머리와 몸의 비율, 남궁/모용/탁문호 탐험 그림과 각 고유 초상화를 참조해 제작했다. 원본 해상도만 보고 채택하지 않고 실제 전투 크기와 공통 발밑 비교표로 대조했다. 마운표·탁문호의 체격 차이는 남기고 같은 표시 범위에서 읽히도록 맞췄다.

`data/battle_visuals.json`이 인물 ID별 원화/초상화/자세 영역/발밑 앵커/기준 신장/연출 색상을 연결한다. 생성 시트의 투명 여백과 칸을 넘어간 무기·머리카락까지 각 자세 영역에 포함한다. 한 인물 안에서는 자세별로 확대율을 바꾸지 않고 웅크림·무기 들기만 다르게 표현한다. 원화에서 반대 방향을 바라보는 자세는 `facing_right`로 먼저 정규화하고, 실제 좌우 위치에 따른 전체 반전을 별도로 적용한다. 보행도 전체 몸과 다리 순서를 함께 반전한다.

`battle_actor.gd`는 기존 동작/피격 깜박임을 전용 자세에 적용한다. `grid_battle.gd`는 상대 `portrait_actor`와 지원 인물 ID로 전용 그림을 고르며, 일반 전투로 바뀌면 공용 그림으로 복귀한다. 전투 상태 카드도 같은 고유 초상화를 사용한다. 공격/피격 효과는 공통 `battle_basic_fx.gd`의 인물별 형태·색상으로 표시한다. 피격 밀림은 실제 공격 방향을 따른다.

## 화면

- [도원과4인·4자세 실제 표시 비교](../../godot/screenshots/dedicated-battle-comparison.png)
- [모용유안 대련](../../godot/screenshots/dedicated-battle-mr_exchange.png)
- [탁문호 전투](../../godot/screenshots/dedicated-battle-cuiyue_tak.png)
- [마운표·남궁서진 지원](../../godot/screenshots/dedicated-battle-qingya_maunpyo.png)
- [탁문호 출수 효과](../../godot/screenshots/dedicated-battle-cuiyue_tak-strike.png)
- [마운표·서진 출수 효과](../../godot/screenshots/dedicated-battle-qingya_maunpyo-strike.png)

## 검증

`tests/dedicated_battle_visuals.gd`는 실제3조우의 전용 시트/4자세/기준 크기/발밑, 출수 전환·피격 깜박임·연출, 이동 시 원화 방향, 좌우 교차와 지원자 전용 시트, 공용 적으로 전환 시 복귀를 검사한다. 실제 격자 공격 이벤트를 재생하며 수치가 원래 조우와 같은지도 검사한다. `grid_opponent_facing.gd`와 `grid_battle_live.gd`로 공통 조작과 방향/이동을 회귀 검사했다. `capture_dedicated_battle.gd`로 비교표와 실제 전투 화면을 생성한다.
