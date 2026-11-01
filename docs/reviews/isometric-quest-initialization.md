# 장사 의뢰 정의와 초기 상태 일치 점검

2026-11-01. 기준은 GitHub `56094c5`의 입력·일시정지·씬 종료 보호를 포함한 장사 시험이다. 로컬은 `b8dd816`이어서 관련 최신 소스·검사를 먼저 합쳤다. 기존 로컬 `project.godot`와 미추적 UID는 해시로 보존을 확인했다. 본게임·저장·배치·속도·배율·보간·미술을 수정하지 않았으며 캡처·영상·혼잡도 시험은 실행하지 않았다.

## 중복 관리와 수정

| 위치 | 역할 | 처리 |
| --- | --- | --- |
| `town-quests.json`의 키 | 의뢰 정의의 ID | 기준으로 사용, 실제 정의는 변경 없음 |
| `iso_town_errands.gd`의 phases/completions | 시작 상태/완료 횟수의 고정 ID | 빈 사전에서 정의를 순회해 누락 키만 available/0으로 채움 |
| selected_quest | 초기 Q 선택의 고정 iso_errand | 선택이 없을 때 첫 정의 사용, 기존 선택 유지 |
| navigation 등록·NPC 연결·조사·Q 행 | 정의를 순회하거나 선택한 ID로 접근 | 기존 방식 유지, 시작 추적은 비어 있음 |
| marker_nodes와 target_label_for | 두 표식 연결과 의뢰별 장소 안내 | 고정 ID 유지: UI/콘텐츠 확장은 후속 범위 |
| iso_errand_tracking.gd와 상위 iso_errand.gd | 이전 단일 의뢰 시험의 기본값 | 비교용 시험을 보존. 장사에서는 자체 초기화·등록/표시 함수를 사용 |
| 기존 실제 플레이 검사 | 대패/항아리의 콘텐츠별 동작 확인 | 의도적으로 두 실제 ID를 명시, 자동 생성 로직과 독립된 기대값 유지 |

`initialize_quests()`는 상태를 초기화하는 재시작 함수가 아니다. 빠진 키만 등록하고 active/ready/completed, 완료 횟수, 선택·추적을 덮어쓰지 않는다. 정의 순서와 관계없이 키로 접근한다. 실행 중 정의 삭제·ID 변경에 따른 기존 상태 이전/삭제는 지원하지 않는다.

잘못된 정의 ID는 기존 정적 검사와 같은 `[A-Za-z][A-Za-z0-9_]*` 형식으로 제한하고, 전체 키를 먼저 검증해 실패 시 상태를 전혀 쓰지 않고 false를 반환한다. 정상 빈 정의는 상태 생성 단계에서 true인 무변경 처리다. **빈 정의로 전체 씬/Q UI가 동작한다고 보장하지 않는다.** 실제 씬은 기존 두 의뢰의 표식·문구를 전제로 한다. 미등록 ID의 상태 변경 요청은 기존 resolve_for의 방어로 무시한다. JSON 중복 키·콘텐츠 필수 필드는 기존 Python 정적 검사에서 확인한다.

## 수정 전후 검사

| 항목 | 수정 전 | 수정 후 / 상태 |
| --- | --- | --- |
| 실제 정의·참조 정적 검사 | 3검사 PASS, 메모리 오류31사례 검출 | 동일 PASS / 통과 |
| 기존 장사 실행 | 270831 assertion PASS | 보강 후270872 PASS / 통과 |
| 기존 입력·모달·전환·종료 상태 | 79항목 PASS | 동일79항목 PASS / 통과 |
| 정의 기반 초기화 | 별도 ID 사전, 추가 단위 검사는 초기화 함수 부재로 FAIL | 함수 추가, 메모리26항목 PASS / 수정 |
| 정의/상태/횟수 키 일치·ID 변경·임시 추가·순서 변경·독립 상태 | 별도 전용 검사 없음 | 실제 파일을 바꾸지 않고 메모리 사본으로 PASS / 통과 |
| 부분 상태 보충·반복 호출·수행/보고/완료·횟수·선택/추적 보존 | 별도 전용 검사 없음 | 단위+실제 씬 검사 PASS / 통과 |
| 두 의뢰 수락/거절/조사/보고·동시 진행·추적 변경·완료 중복 방지 | 기존 정상 동작 | 실제 입력 회귀 PASS / 통과 |
| Q 각 행과 머리 위 !/? 상태 | 기존 표시 | 상태별 노드의 text/visible 검사 PASS / 통과 |
| 실내/거래 후 보존·R 위치 초기화·새 실행 초기화 | 기존 정상 동작 | 진행/횟수/추적/선택/돈/소지품 검사 PASS / 통과 |
| 세 번째 실제 의뢰·빈 정의 씬·다중 의뢰 UI 확장 | 대상 아님 | 미확인, 구현하지 않음 |
| 화면 배치·미술·성능·혼잡도 | 대상 아님 | 미확인, 캡처/측정하지 않음 |

재사용: `check_isometric_town_data.py`, `isometric_town_structure.gd`, `isometric_town.gd`의 기존 이동·의뢰·거래/입력 검사. 추가: 상태 생성만 검사하는 `isometric_town_state.gd` 26항목, 기존 장사 검사 안의 표식/Q·반복 초기화·R·새 실행·정지 상태 씬 종료 확인. Godot4.7.2 headless/Dummy/고정60FPS, 별도 APPDATA에서 검사했다. 화면의 글자·가시성은 노드 상태로 확인했으며 픽셀 렌더링 검사는 하지 않았다. 환경의 인증서 저장소 오류는 수정 전후 동일하며 스크립트 오류는 없었다.

## 실제 의뢰 추가 전에 남은 작업

1. 표식 생성과 의뢰별 장소 문구를 새 정의/NPC에 연결할 방법을 정한다. 현재 대패 분기 외에는 항아리 문구가 된다.
2. 두 행의 고정 가로 배치를 넘어서는 Q 선택·추적 UI를 별도로 설계/검사한다.
3. NPC·초상화·대화·실제 조사 물건·좌표/접근점과 정적 검사의 참조를 연결한다. 상태 등록 성공만으로 이 연결을 검증할 수 없다.
4. 실제 새 콘텐츠의 수락/거절·동시 수행·보고·추적/표식·실내/거래·입력/종료 회귀를 추가한다. 이번에는 세 번째 실제 의뢰를 만들지 않았다.

## 실행

`C:\Users\PC\murim-rpg\godot\project.godot`을 열고 `res://prototypes/isometric/changsha.tscn`을 **F6**으로 실행한다. F5는 본게임이다. 로컬에는 수정이 적용되어 있다. 다른 작업본의 업데이트는 아래처럼 한다. 미커밋 변경과 겹치면 Git이 중단하므로 강제 초기화하지 않는다.

```powershell
Set-Location C:\Users\PC\murim-rpg
git pull --ff-only origin main
```

검사 재현(별도 PowerShell에서 실행):

```powershell
Set-Location C:\Users\PC\murim-rpg
$env:APPDATA = Join-Path $env:TEMP ('murim-quest-check-' + [guid]::NewGuid().ToString('N'))
$godotExe = 'C:\Users\PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& 'C:\Users\PC\AppData\Local\Python\pythoncore-3.14-64\python.exe' godot/tests/check_isometric_town_data.py
foreach ($case in @('isometric_town_state', 'isometric_town_structure', 'isometric_town')) {
    & $godotExe --headless --audio-driver Dummy --fixed-fps 60 --path godot --script "res://tests/$case.gd"
}
```
