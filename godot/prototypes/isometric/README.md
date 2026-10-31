# 아이소메트릭 독립 시험 씬

본게임 변환 전 공간 표현과 대화 연결을 검증하는 작은 씬이다. 본게임 시작 씬은 실행하지 않고 도시·저장·전투·의뢰 진행과 분리한다. 공용 대화 UI만 재사용하며 중단한 농지/부두 작업도 유지한다.

## 실행과 업데이트

PowerShell에서:

```powershell
cd C:\Users\PC\murim-rpg
git pull --ff-only
```

기존 `godot/project.godot` 프로젝트에서 `res://prototypes/isometric/main.tscn`을 열고 **F6**. 실제 파일은 `C:\Users\PC\murim-rpg\godot\prototypes\isometric\main.tscn`이다. F5는 기존 본게임이다.

```sh
godot --path godot res://prototypes/isometric/main.tscn
```

화면과 영상을 한 페이지에서 보려면:

```powershell
Start-Process .\godot\prototypes\isometric\screenshots\gait-access-preview.html
```

| 조작 | 동작 |
| --- | --- |
| WASD / 방향키 | 화면 방향으로 도원 이동 |
| F | 가까운 접근 가능한 NPC 대화 / 다음 줄. NPC가 없으면 기존 시험용 조사 |
| 왼쪽 클릭 | 시험용 선택만 수행. 이동/대화 진입 없음. 대화의 다음 버튼은 클릭 가능 |
| H | 탐험 중 가림 표시 / 대화 중 이미 읽은 줄의 기록 |
| H / ESC | 기록 창에서 대화로 복귀 |
| 휠 / 중간 버튼 드래그 / C | 탐험 중 확대·수동 이동·카메라 추적 |
| G | 탐험 중 실제 바닥 충돌과 두 건물의 문 앞 접근 경로 |
| P | 탐험 중 자동 왕복 정지/재개. 충돌 유지 |
| R | 탐험 중 세 인물을 시작 위치로 초기화 |

## 현재 시험 범위

12×12논리 바닥, 민가/창고/열린 대문,13구간 담장, 나무/항아리, 조작 도원1명과 자동 짐꾼2명이다. 넓은 마당→대문→골목/건물 뒤쪽 길을 연결한다. 골목 폭1.45, 문 통로1.15, 인물 발밑 지름0.30이며 문기둥만 통행을 막는다. 건물 좌표/중앙 통로/왕복 경로와 세 인물의 속도4.8논리 타일/초는 유지했다. 창고 문 쪽에는 하역 마당과 폭1.4의 담장 출입구를 추가해 공용 마당에서 접근하게 했다. 두 건물은 실내가 없어도 문 위치/앞마당/접근 경로를 등록하며 시작/G키에서 검사한다.

도원은96표시 높이의 청색 무복·흰 깃·갈색 띠·검은 포니테일이다. 짐꾼 원본을 비율/화풍 기준으로 삼았고 회벽/기단/기와와 나무/항아리 원본, 바닥 문턱/접지 그림자를 사용한다. 그림자는 모든 인물보다 아래다. 현재 바닥은144기본 폴리곤과 연속 포장이며 도시용 TileMap 구조는 확정하지 않았다.

보행은 앞/뒤 원본의 좌우 반전과 전신 관절 메시 변형이다. 무릎을 굽혀 발을 교차하고, 팔은 반대 위상으로 흔들며 몸통은 약3~4픽셀 상하 이동한다. 머리/사지 길이·배율과 발밑 물리 기준점은 유지한다. 새8장 원화가 아니라 연속 보행의8대표 자세를 검증한 방식이다. W+D를 떼는 순서 때문에 잠깐 남는 단일 방향 입력은 정지 방향으로 덮어쓰지 않는다. 단일 방향으로 계속 걸거나 새 방향 키를 누르면 정상 전환한다.

자동 NPC는 문간/골목과 창고 옆/뒤 길을 왕복하며 조작 인물을 우선해 옆으로 양보/대기/후퇴한다. 범용 길찾기는 없다. 가림 표시 색은 도원 금색/NPC 청색이며 이름표 겹침을 피한다.

## F 대화와 재사용

1.25논리 타일 안의 NPC 중 실제 발밑 경로가 열려 있고 완전히 가려지지 않은 가장 가까운 한 명에게 이름/F 대화/금색 발밑을 표시한다. 벽·건물 모서리·기둥·다른 인물이 막으면 제외하며 열린 문은 통과한다. 대화 대상 표식과 가림 이름표는 중복하지 않는다.

문길/뒷길 짐꾼에게 각각5줄의 일상 대화가 있다. 기존 `paper_dialogue_panel.gd`, `paper_menu_base.gd`, `dialogue_portraits.gd`, `dialogue_history.gd`를 직접 사용한다. 기존 도원/공용 초상화만 재사용하며 도원 왼쪽/상대 오른쪽, 비화자와 배경 어둡게 처리를 유지한다. 본게임 `main.gd`의 진행 관리자는 연결하지 않는다.

대화 중 도원과 상대만 멈추고 다른 짐꾼은 왕복한다. 종료 후 상대는 같은 경로를 이어가고 도원은 이동 키를 뗀 뒤 새로 눌러 움직인다. F를 누른 채로 다시 대화가 열리지 않는다. 기록 창은 공용 구현대로 읽는 동안 장면 전체가 잠깐 멈추고 닫으면 원래 상태로 돌아간다. 미래 대사/이야기/의뢰/보상/호의도/저장 연동은 없다.

## 구조와 제약

- `iso_space.gd`: 논리↔화면 투영/기존 단위 어댑터. `layout.json`은 시험 배치와 문/마당/접근 경로다.
- `iso_actor.gd`, `iso_walk_rig.gd`: 발밑 물리/고정 크기/4방향 보행과 정지 방향.
- `iso_prop.gd`, `iso_wall.gd`, `iso_grounding.gd`: 분리된 그림/바닥 충돌/담장 재질/바닥 접지.
- `iso_access_rules.gd`: 실내 유무와 무관한 문/접근 방향/마당·공용 길·충돌 검사.
- `iso_patrol.gd`: 정해진 길의 왕복/양보. `iso_visibility_hint.gd`: 여러 인물의 가림 표시.
- `iso_interaction.gd`: 대상 한 명의 거리/접근/가림 검사와 안내.
- `iso_dialogue.gd`: 공용 UI의 시험용 호스트. `dialogues.json`: 지역 이름/기존 초상화 참조/각5줄.
- `iso_world.gd`: 배치/깊이/카메라/시험 안내와 컴포넌트 연결. `assets/manifest.json`: 원본 영역/발밑/스케일.

재사용 범위/검증/남은 문제는 [보행·진입 동선 보고서](../../../docs/reviews/isometric-gait-access.md)와 [대화 연결 보고서](../../../docs/reviews/isometric-dialogue.md)를 따른다. 긴 대사의 자동 레이아웃/설정/선택지·진행/저장은 연결하지 않았다. 전체 도시와 많은 NPC는 별도 검증이 필요하다.

## 실제 화면과 검사

[최신 전후·보행 확인](screenshots/gait-access-preview.html) · [11.8초 영상](screenshots/gait-access-play.mp4) · [건물 배치 규칙](../../../docs/cities/building-placement.md)


[확인 페이지](screenshots/dialogue-preview.html) · [영상10.7초](screenshots/dialogue-play.mp4) · [F 대상](screenshots/dialogue-target.png) · [상대 발언](screenshots/dialogue-npc.png) · [도원 발언](screenshots/dialogue-hero.png) · [기록](screenshots/dialogue-history.png) · [1440p](screenshots/dialogue-1440p.png)

[W+D 이동](screenshots/dialogue-facing-moving.png) · [정지 후 방향 유지](screenshots/dialogue-facing-idle.png) · [이전 미술 비교](screenshots/harmony-comparison.html)

```sh
godot --headless --path godot --script res://tests/isometric_prototype.gd
godot --headless --path godot --script res://tests/isometric_alley.gd
godot --headless --fixed-fps 60 --path godot --script res://tests/isometric_walkers.gd
godot --headless --path godot --script res://tests/isometric_harmony.gd
godot --path godot --audio-driver Dummy --script res://tests/isometric_walk_render.gd
godot --headless --fixed-fps 60 --path godot --script res://tests/isometric_dialogue.gd
godot --headless --fixed-fps 60 --path godot --script res://tests/isometric_gait_access.gd
```

최신 `tests/capture_gait_access.gd`는 변경 후 전체/접근 동선/창고 문/8자세/앞뒤/정지 화면을 촬영한다. `--fixed-fps 30 --write-movie /tmp/gait-access.avi`로 보행과 이동을 기록할 수 있다.

이전 대화 기록은 실제로 렌더링 가능한 환경에서 `tests/capture_isometric_dialogue.gd`를 실행하면9장을 촬영한다. `--fixed-fps 30 --write-movie /tmp/iso-dialogue.avi`를 함께 지정하면 입력과 비교 배치를 기록한다. 사용자 저장과 분리한 XDG 폴더를 권장한다.

이전 [미술 조화](../../../docs/reviews/isometric-harmony.md)/`harmony-*`, [보행](../../../docs/reviews/isometric-walkers.md)/`walkers-*`, [골목](../../../docs/reviews/isometric-alley.md)/`alley-*`, [최소 씬](../../../docs/reviews/isometric-prototype.md)은 각 단계의 기록이다. 후속 도시 확대는 사용자 검토 후다.
