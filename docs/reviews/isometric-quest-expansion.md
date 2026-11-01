# 장사 시험 · 의뢰 표시와 Q 목록 확장 준비

2026-11-01, 기준 `4924a14`. 기존 로컬 변경을 보관하고 범위 밖 파일의 SHA256 일치를 확인했다. 본게임·저장·경제·맵/NPC 배치·속도4.8·기본85% 배율·보행·보간은 변경하지 않았다. 실제 의뢰/NPC/대화/상품을 추가하지 않았고 혼잡도·성능 측정·새 미술·영상도 진행하지 않았다.

## 변경

- `iso_town_errands.gd`: 정의별 표식 생성/등록, 빈 정의의 빈 navigation 등록, 잘못된 ID의 선택/상세/추적/목표/대사 접근 방어. 유효한 제공자가 없으면 표식을 숨긴다.
- `town-quests.json`: 기존 두 의뢰의 실외/실내 목표 문구를 `objectives.outside/room`으로 명시했다. 기존 문구와 대사·장소·좌표·상태/완료 조건은 유지한다. 새 ID가 항아리 안내로 처리되는 기본 분기를 없앴다. 보고 안내는 해당 제공자 이름으로 만든다.
- Q: 고정 가로 두 칸을 세로 스크롤 목록과 별도 상세 스크롤 영역으로 변경했다. 선택은 녹색 테두리로 표시하고, 실제 추적 의뢰는 상세 위에 따로 표시한다. ↑↓/Home/End/PageUp/PageDown으로 목록 선택, Enter/Space로 추적·해제, Q/ESC로 닫는다. 마우스 선택/휠도 지원한다. 빈 목록은 안내와 비활성 추적 버튼을 표시한다.
- 수락한 다른 의뢰의 진행/완료는 추적을 빼앗지 않으며, 추적 의뢰 완료 시 다른 의뢰를 자동 선택하지 않는다. 현재 두 의뢰의 상태 표시 범위는 유지했다. 본게임 일지의 필터 정책을 바꾸지 않았다.
- `iso_town_dialogue.gd`: 잘못된 조사 ID를 안전하게 거절한다.
- 기존 Python 정적 검사에 목표 문구 필드를 추가하고 메모리 오류5사례를 보강했다.

## 검사 결과

| 검사 | 수정 전 | 수정 후 |
| --- | --- | --- |
| 기존 정적 검사 | 3검사 PASS / 메모리 오류31사례 | 3검사 PASS / 오류36사례 |
| 정의 기반 초기화 | 26항목 PASS | 동일26항목 PASS |
| 입력/일시정지/전환/씬 종료 상태 | 79항목 PASS | 동일79항목 PASS |
| 실제 장사 두 의뢰·거래·이동 회귀 | 270872 assertion PASS | 동일270872 PASS |
| 새 목록/ID/표식/안내 검사 | 해당 전용 검사 없음 | 235항목 PASS |
| 실제 두 의뢰 UI 렌더 | 기존 가로 배치 | 선택/추적 구분과 목록/상세 영역을 로컬 PNG1장으로 확인 |

새 `tests/isometric_town_journal.gd`는 기존 장사 검사 도우미를 재사용한다. 실제 두 의뢰의 실외/실내 안내와 잘못된 ID 방어를 검사한 뒤, 메모리 사본0·1·3·10·30개로 정의/상태/navigation/표식/행의 등록 수, 새 ID의 !/? 상태, 목록 전 항목의 선택/상세/추적 가능 여부, 키보드 끝 항목 접근, 실제 휠 이벤트와 스크롤 후 클릭, 긴 상세 스크롤, 추적 독립성·완료 중복 방지를 확인한다. 검사 종료 시 실제 의뢰 JSON이 변하지 않았는지도 확인한다.

첫 스크롤 클릭 검사는 자동 입력에 휠 버튼 해제가 빠져 실패했다. 휠 입력을 누름/해제 쌍으로 수정한 뒤 통과했다. 제품 코드의 클릭 우회는 추가하지 않았다.

Godot4.7.2 headless/Dummy/고정60FPS와 별도 APPDATA를 사용했다. UI 렌더만 같은 해상도1280×720의 실제 렌더 창에서 확인했다. 원래 있던 인증서 저장소 경고는 게임 실패로 집계하지 않았으며 스크립트 오류는 없었다.

## 남은 범위

- 메모리30개는 UI 용량/상태 연결 검사다. 실제30개 의뢰의 대화/수행/콘텐츠 연결이나30명 NPC의 배치·표식 겹침·성능을 검증하지 않았다. 표식 상태 검사는 기존 제공자를 재사용한다.
- 실제 의뢰 추가 시 제공자·초상화·일반 대화 등록·조사 물건과 좌표, 실내/실외 안내를 명시하고 실제 수행 회귀 검사를 추가해야 한다.
- 동일 NPC의 복수 의뢰는 여전히 첫 일치 의뢰를 선택한다. 같은 NPC가 여러 의뢰를 주는 콘텐츠를 만들 때 용건 선택을 별도로 다룬다.
- 가상화 목록·범용 의뢰 제작 도구·본게임 적용·새 저장 형식은 구현하지 않았다. 30개를 넘는 규모와 다른 해상도/글자 크기는 미검증이다.

## 실행과 업데이트

로컬에는 적용되어 있다. `C:\Users\PC\murim-rpg\godot\project.godot`을 열고 **`C:\Users\PC\murim-rpg\godot\prototypes\isometric\changsha.tscn`에서 F6**으로 실행한다. F5는 본게임이다.

다른 작업본 업데이트:

```powershell
Set-Location C:\Users\PC\murim-rpg
git pull --ff-only origin main
```

미커밋 변경과 겹치면 Git이 중단한다. 기존 변경을 강제 초기화하지 않는다. 검사 재현은 별도 PowerShell에서 실행한다.

```powershell
Set-Location C:\Users\PC\murim-rpg
$env:APPDATA = Join-Path $env:TEMP ('murim-journal-check-' + [guid]::NewGuid().ToString('N'))
$godotExe = 'C:\Users\PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& 'C:\Users\PC\AppData\Local\Python\pythoncore-3.14-64\python.exe' godot/tests/check_isometric_town_data.py
foreach ($case in @('isometric_town_state', 'isometric_town_journal', 'isometric_town_structure', 'isometric_town')) {
    & $godotExe --headless --audio-driver Dummy --fixed-fps 60 --path godot --script "res://tests/$case.gd"
}
```
