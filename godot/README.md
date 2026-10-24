# Godot 4 · 명초 무협 RPG

본게임 프로젝트입니다. **Godot 4.6 이상 Standard**에서 `project.godot`을 열고 F5로 실행합니다. Compatibility 렌더러·GDScript를 사용합니다.

현재 구현 범위와 미구현 항목은 [CLI 인계](../docs/CLI_HANDOFF.md), 기능별 문서·검사는 [작업 색인](../docs/README.md), 콘텐츠 수정 규칙은 [AGENTS.md](AGENTS.md)를 참고하세요.

## 실행과 조작

저장소를 내려받은 폴더에서 `git pull --ff-only`로 최신 내용을 받은 뒤 Godot에서 `godot/project.godot`을 가져옵니다. 처음에는 자산 가져오기를 기다리고 F5를 누릅니다. 타이틀에서 표행 시작·장사 자유 탐방·전투 체험을 선택합니다. 기존 저장이 있으면 이어하기를 사용할 수 있습니다.

| 키 | 기능 |
| --- | --- |
| WASD / 방향키 / 바닥 클릭 | 이동(기존 대비2배 속도) |
| F | 가까운 인물과 대화·다음 대사·승선·시설 진입 |
| I / K | 소지품 / 무공과 4칸 편성 |
| Q | 의뢰 일지·의뢰인 위치 안내·목표 추적 |
| F2 | 조작과 시스템 도움말 |
| L | 이미 실행된 교전 기록·결산 |
| H (대화 중) | 현재까지의 대화 기록 열기/닫기 |
| TAB | 장사 전체 지도 |
| ESC | 설정 또는 열린 창 닫기 |
| M | BGM 음소거 전환 |
| 전투 행동 클릭 → 사용 / Enter | 설명 확인 후 실행 |
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
