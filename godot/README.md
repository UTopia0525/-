# Godot 4 · 명초 무협 RPG

본게임 프로젝트입니다. **Godot 4.6 이상 Standard**에서 `project.godot`을 열고 F5로 실행합니다. Compatibility 렌더러·GDScript를 사용합니다.

현재 구현 범위와 미구현 항목은 [CLI 인계](../docs/CLI_HANDOFF.md), 기능별 문서·검사는 [작업 색인](../docs/README.md), 콘텐츠 수정 규칙은 [AGENTS.md](AGENTS.md)를 참고하세요.

최근 미술 변경: [44종 인물의 대화 표정](../docs/systems/dialogue-expressions.md), [남경 전역의 재질·건물 비율 개선](../docs/cities/nanjing-painted.md). 이 변경은 본2D 게임에 적용되어 있으며 별도3D 항주 프로젝트와 구분합니다.

## 실행과 조작

맵 이동은 키보드 전용이며 인물·사물·포탈 근처에서 F로 상호작용합니다. 맵을 클릭해도 이동하거나 대화하지 않습니다. 전투·거래·인벤토리·대화의 다음 버튼 등 UI는 마우스로 선택할 수 있습니다.

저장소를 내려받은 폴더에서 `git pull --ff-only`로 최신 내용을 받은 뒤 Godot에서 `godot/project.godot`을 가져옵니다. 처음에는 자산 가져오기를 기다리고 F5를 누릅니다. 타이틀에서 표행 시작·장사 자유 탐방·전투 체험을 선택합니다. ‘무창 자유 탐방’에서는 민간 주민8명과 대화하고 영약상·장인·교관에게 거래할 수 있으며 남문에서 시작합니다. 장사 동문 밖 농촌의 동쪽 끝과 무창 남문 밖 농촌의 남쪽 끝에 있는 푸른 포탈에서 F로 산길을 왕복할 수 있습니다. 기존 저장이 있으면 이어하기를 사용할 수 있습니다.

| 키 | 기능 |
| --- | --- |
| WASD / 방향키 | 이동(기존 대비2배 속도) |
| F | 가까운 인물과 대화·다음 대사·승선·시설 진입 |
| I / K | 소지품 / 무공과 4칸 편성 |
| Q | 의뢰 일지·의뢰인 위치 안내·목표 추적 |
| F2 | 조작과 시스템 도움말 |
| L | 이미 실행된 교전 기록·결산 |
| H (대화 중) | 현재까지의 대화 기록 열기/닫기 |
| TAB | 장사 전체 지도 |
| ESC | 설정 또는 열린 창 닫기 |
| M | BGM 음소거 전환 |
| 전투 WASD/방향키 · 1~4 · R · Enter | 격자 이동 · 초식 선택 · 방향 전환 · 출수 |
| F1 | 타이틀로 초기화 |

ESC → 환경 설정·도움말에서 BGM/효과음 음량, 화면 모드, 대화·도움말·기록 글자 크기를 바꿀 수 있습니다. 노란 !는 의뢰인, ?는 달성 후 보고 대기입니다. [편의 기능8종과 일반 의뢰](../docs/systems/adventure-usability.md).

수동 저장10슬롯은 탐험·분기 선택창에서 사용할 수 있습니다. 대화·거래·전투 중 새 저장은 차단합니다. 과거 버전 저장은 읽기 호환을 유지합니다. [저장 위치·제한](../docs/systems/save-slots.md).

## 구조

- `scenes/`: 시작·탐험·플레이어·전투 장면
- `scripts/`: 진행·대화·이동·전투·거래·저장 코드
- `data/`: 무공·무기·대사·성장·아이콘 등 런타임 데이터
- `assets/`: 게임 실행 자산과 자산별 제작 설명
- `tests/`: 기존 기능 검사와 화면 캡처 도구
- `screenshots/`: 문서용 실행 화면

초상화 원본 `../assets/portraits/`, 이전 웹 데모 `../demo/`, 세계지도 도구 `../world-map/`도 별도로 보관합니다.

## 개발 검증

저장소 루트에서 Godot 실행 파일을 `godot` 명령으로 사용할 수 있어야 합니다. 프로젝트 가져오기:

```sh
godot --headless --path godot --editor --import --quit
```

검사는 실제 플레이 저장과 분리한 사용자 데이터 폴더에서 실행합니다. Linux/macOS 셸 예시:

```sh
XDG_DATA_HOME="$(mktemp -d)" godot --headless --audio-driver Dummy --path godot --script res://tests/smoke.gd
```

Windows PowerShell 예시(현재 셸에서 실행할 때만 APPDATA를 바꾸고 종료 후 복원):

```powershell
$gameTestData = Join-Path ([IO.Path]::GetTempPath()) ("murim-tests-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $gameTestData | Out-Null
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $gameTestData
    godot --headless --audio-driver Dummy --path godot --script res://tests/smoke.gd
} finally {
    $env:APPDATA = $previousAppData
}
```

`smoke.gd`를 [작업 색인](../docs/README.md)에 있는 해당 기능 검사로 바꾸어 실행합니다. 공통 저장·전투·진행을 바꾸면 관련 회귀 검사도 실행합니다. 캡처는 그래픽 환경에서 `tests/capture*.gd`를 선택해 실행하고 결과를 검토합니다.

## 화면과 상세 자료

- [독립 건물·문 가림·공용 초상화·대화 기록](../docs/systems/layered-city-and-conversation.md)
- [장사 지도와 탐험의 이전 개편](../docs/cities/changsha-redesign.md)
- [전투·아이콘·4칸 편성](../docs/systems/combat-actions-and-icons.md)
- [무협 UI와 서체](../docs/systems/wuxia-ui-style.md)
- [전투 모션](../docs/systems/battle-motion.md)
- [초상화 비율과 시선](../docs/systems/dialogue-portraits.md)
- [애니메이션 자산](assets/animation/README.md) · [BGM](assets/music/README.md)
- [이전 README 전체 기록](../docs/archive/godot-readme-before-cleanup.md): 당시의 화면·단계별 한계 설명을 보존합니다.

- [탐험 인물 크기·이동 속도](../docs/systems/exploration-scale.md)

- [무창 지도 답사·무림맹 본단](../docs/cities/wuchang.md)

- [장사–무창 산길·왕복·저장](../docs/cities/changsha-wuchang-road.md)

- [무창 민간 주민8명·대사·초상화](../docs/characters/wuchang-civilians.md)

## 남경 구휼 의뢰

무창 동쪽→삼거리 산촌 동쪽 포탈→남경 객잔의 육소전에게 F. 무림맹에서 중급 무공을 전수받은 뒤 수락할 수 있으며, 범인 인계 후500문·남궁세가 호의도+10을 받는다. [진행과 실제 화면](../docs/quests/nanjing-relief.md). 별도 데모 내보내기 없이 F5로 실행한다.

현재 전투는 [가변 격자 전투](../docs/systems/grid-combat.md)입니다. 기본7×5이며 조우별 크기·지형 자료를 지원합니다. 새 엔진은 `tests/grid_combat.gd`, `grid_battle_live.gd`, `grid_story_integration.gd`, `grid_campaign.gd`로 확인합니다. 이전 교환식 전투의 고정 차례/예고를 가정한 UI 검사는 새 전투의 기준이 아닙니다.
