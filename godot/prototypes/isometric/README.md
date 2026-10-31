# 아이소메트릭 독립 시험 씬

본게임 변환 전 공간 표현을 검증하는 작은 씬이다. 본게임 시작 씬·도시·저장·전투·의뢰 코드를 불러오지 않는다. 앞서 중단한 농지/부두 작업과도 분리되어 있다.

## 실행

1. 기존 `godot/project.godot` 프로젝트를 Godot4.6 이상에서 연다.
2. 파일시스템에서 `prototypes/isometric/main.tscn`을 연다.
3. **F6(현재 씬 실행)**을 누른다. **F5는 기존 본게임**을 실행한다.

CLI에서 Godot 실행 파일을 사용할 수 있다면 저장소 루트에서 다음처럼 실행할 수 있다.

```sh
godot --path godot res://prototypes/isometric/main.tscn
```

| 조작 | 동작 |
| --- | --- |
| WASD / 방향키 | 화면 방향으로 시험용 NPC 이동 |
| F | 가까운 오브젝트 시험용 조사 문구 |
| 왼쪽 클릭 | 보이는 NPC·건물·장식 선택. 이동하지 않음 |
| 휠 | 확대/축소 |
| 중간 버튼 드래그 | 카메라 수동 이동 |
| C | 카메라 추적 켜기/끄기 |
| G | 바닥 타일·바닥 점유 범위 표시 |
| H | 인물이 가려질 때 금색 위치 표시 켜기/끄기 |
| P | 자동 NPC 왕복 정지/재개. 충돌은 유지 |
| R | 조작 인물과 자동 NPC를 시작 위치로 초기화 |

## 들어 있는 것

12×12 논리 바닥에 기존 민가·창고, 넓은 마당→열린 대문→좁은 골목을 배치했다. 담장은15개 짧은 구간으로 나눠 앞뒤 정렬한다. 나무·항아리 각1개는 도형 장식이다. 이번 보행 시험에서는 **조작 짐꾼1명+같은 외형의 자동 NPC2명**이 움직인다. 문길 짐꾼은 마당/대문/골목, 뒷길 짐꾼은 창고 옆/건물 뒤쪽 길을 왕복한다. 건물 배치는 이전 골목과 같다.

기존 앞/뒤 대각선 그림을 좌우 반전해4방향으로 표현한다. 보행은 기존 그림을 텍스처로 쓴 런타임 메시에서 **두 다리를 반대 위상으로 움직이는 방식**이다. 상체 크기/그림 비율/공통 발밑 기준은 고정하며, 정지하면 같은 원본의 대기 자세로 돌아간다. 별도 손그림 보행 시트는 채택하지 않았다. 벽에 막혀 실제로 움직이지 않으면 발만 계속 걷지 않는다.

골목 폭은1.45논리 타일, 대문 통로는1.15타일, 인물 발밑 지름은0.30타일이다. 대문 양쪽 기둥만 충돌하고 중앙은 열려 있다. G로 실제 충돌 바닥을 확인할 수 있다. 지붕 아래에서는 대문 그림이 인물 앞에 오지만 투명한 개구부로 인물이 보인다.

인물끼리도 발밑 충돌이 있다. 조작 인물을 우선하고 자동 NPC는 옆으로 양보하거나 잠시 기다린 뒤 이전 경유점으로 물러선다. 사전에 지정한 길과 작은 회피만 사용하며 범용 길찾기는 없다.

가림 대응안은 **가려질 때만 나타나는 발밑 고리·점선·이름표**다. 조작 인물은 금색, 자동 NPC는 청색으로 구분한다. H로 비교할 수 있다. 세 인물의 이름표가 겹치면 화면 안의 다른 자리로 옮겨 연결선을 표시한다. 지붕/담장을 투명하게 만들거나 가려진 인물을 클릭 가능하게 바꾸지 않는다.

돌/흙 바닥은 기존 재질을 마름모에 매핑해 그린다. 이번 씬은 `TileMapLayer`를 사용하지 않고144개의 바닥 폴리곤을 그리는 방식이며, 대규모 도시용 타일 시스템을 확정한 결과가 아니다.

## 구조

- `iso_space.gd`: 연속 논리 좌표↔화면 좌표 변환. 타일128×64. 기존 미술 좌표 배열을 논리 타일 단위로 읽는 작은 어댑터 포함.
- `layout.json`: 시험 전용 점유 사각형/이름/ID. 기존 도시 JSON은 수정하지 않는다.
- `iso_prop.gd`: 논리 바닥을 화면 다각형 충돌체로 변환하고 그림의 지상 앞쪽 모서리에 맞춰 등록한다. 이미지 종횡비는 유지한다.
- `iso_wall.gd`: 짧은 담장 구간의 투영 바닥/충돌과 높이가 일정한 입체 면을 만든다. 기존 시장 재질을 사용한다.
- `iso_visibility_hint.gd`: 가림 감지 결과를 화면 좌표로 표시한다. 물리/선택 판정은 바꾸지 않는다.
- `iso_actor.gd`: 화면 방향 입력을 논리 방향으로 역변환해 이동하고 충돌 후 실제 위치에서 논리 위치를 갱신한다. 원형 논리 발밑은 화면에서 타원 다각형이다.
- `iso_walk_rig.gd`: 기존 인물 그림의 고정 상체/독립 다리 변형. 렌더와 클릭 모두 같은 변형 삼각형을 사용한다.
- `iso_patrol.gd`: 지정 경유점 왕복·옆으로 양보·대기·후퇴. 조작 인물 우선, NPC끼리는 고정 우선순위를 쓴다.
- `iso_world.gd`: 배치·깊이·카메라·시험 안내. 불명확한 정렬은 화면Y로 결정하고 명확한 논리 앞뒤 관계는 우선한다. 단순 발밑Y 하나보다 건물 옆면에 유리하다.
- `assets/manifest.json`: 이미지 영역·바닥 기준점·스케일. 원본 크기를 논리 충돌 면적으로 잘못 사용하는 것을 피한다.

조작 속도는 **논리 지상 거리 기준 초당4.8타일**로 이전2.4의 정확히2배다. 2:1 투영 때문에 화면에서 수직 이동 속도는 수평보다 작게 보인다. 본게임 이동 속도는 변경하지 않았다.

## 확인 화면

[실제 플레이 영상16.7초](screenshots/walkers-play.mp4) · [마당](screenshots/walkers-courtyard.png) · [대문 통과](screenshots/walkers-gate.png) · [건물 뒤](screenshots/walkers-behind.png) · [마당 복귀](screenshots/walkers-return.png) · [세 이름표](screenshots/walkers-labels.png) · [1440p](screenshots/walkers-1440p.png)

[보행 단계0](screenshots/walkers-step-0.png) · [왼발/오른발 접지 비교1](screenshots/walkers-step-1.png) · [단계2](screenshots/walkers-step-2.png) · [반대 접지3](screenshots/walkers-step-3.png)

검사/제약은 [최신 보행·여러 NPC 보고서](../../../docs/reviews/isometric-walkers.md)를 따른다. [골목 보고서](../../../docs/reviews/isometric-alley.md)와 `alley-*` 화면은2단계, [최소 씬 보고서](../../../docs/reviews/isometric-prototype.md)와 접두어 없는 화면은1단계 기록이다. 다음 구역으로 자동 확장하지 않는다.

```sh
godot --headless --path godot --script res://tests/isometric_prototype.gd
godot --headless --path godot --script res://tests/isometric_alley.gd
godot --headless --fixed-fps 60 --path godot --script res://tests/isometric_walkers.gd
godot --path godot --audio-driver Dummy --script res://tests/isometric_walk_render.gd
```

실제 렌더링 가능한 환경에서 `tests/capture_isometric_walkers.gd`를 실행하면 최신10장을 다시 촬영한다. `--fixed-fps 30 --write-movie /tmp/iso-walkers.avi`를 함께 지정하면 입력 이동과 비교 배치를 영상으로 기록한다. 저장은 사용하지 않으며 본게임 검사와 분리한다.
