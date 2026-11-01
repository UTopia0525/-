# 장사 시험 · 의뢰/NPC/대화/상점 연결

2026-11-01, 기준 `77f70cc`. 현재 실제 의뢰2개와 상인의 연결은 정상이다. 확장 시 드러나는 연결 위험만 점검하고 다음을 최소 수정했다.

| 항목 | 수정 전 | 수정 후 |
| --- | --- | --- |
| 의뢰 제공자의 대화 시작 등록 누락 | 메모리에서 GatePorter 등록을 지워도 정적 오류0개 | `giver_dialogue`로 검출 |
| 시작 발화자/의뢰 초상화 불일치·잘못된 대사 | actor 존재만 확인해 일부 누락 | 등록 대사의 형태·발화자 참조·첫 발화자와 의뢰 actor 일치 검사 |
| 의뢰 없는 일반 NPC의 대화 | 모든 비의뢰 대화를 trade로 예약 | 실제 `TownMerchant`만 trade 예약 |
| 같은 NPC의 복수 의뢰 | 정의 순서상 첫 의뢰만 선택 | 제한 유지, 용건 선택은 구현하지 않음 |

`iso_town_dialogue.gd`의 상점 분기1줄만 수정했다. 실제 NPC/의뢰/대사/상품·본게임/저장/경제/UI/배치/속도/배율/보간은 변경하지 않았다. 기존 로컬 변경은 보관하고 범위 밖 파일 해시 일치를 확인했다. 캡처·영상·미술·혼잡도/성능 검사는 실행하지 않았다.

검사:

- 기존 Python 정적 검사3종: 수정 전 PASS/메모리 오류36사례 → 수정 후 PASS/43사례. 추가7사례는 실제 JSON을 바꾸지 않는 메모리 사본이다.
- 새 `tests/isometric_town_links.gd`: 수정 전19항목 중 일반 NPC의 상점 예약/열기2항목 FAIL → 수정 후19항목 PASS. 기존 NPC의 의뢰 연결만 메모리에서 잠시 제거해 일반 대화를 검사한다. 대화 등록 누락 시 시작 실패와 상태/정지 보존, 실제 상인의 F→대화 완료→상점, 기존 의뢰의 보고/완료 후 대화도 확인했다.
- 분기 변경에 영향받는 기존 `isometric_town.gd`만 수정 후 한 번 실행: PASS(270872 assertion).
- 초기화26·상태 보호79·Q 확장235항목은 이전 통과 결과를 재사용했다. 새로 실행한 것으로 집계하지 않는다.

Godot4.7.2 headless/Dummy/고정60FPS, 별도 APPDATA를 사용했다. 기존 인증서 저장소 경고 외 스크립트 오류는 없었다.

이제 이 독립 시험의 연결 안전성 점검은 여기서 끝내도 된다. 확장은 **NPC별 의뢰1개·등록된 단일 NPC와 도원의 대화·현재 실내/실외 구조**를 기준으로 진행할 수 있다. 실제 콘텐츠를 추가할 때 제공자/대화/초상화/조사 대상과 좌표를 연결하고 추가분의 수행 검사를 한다. 동일 NPC의 여러 의뢰, 여러 NPC가 참여하는 대화, 새 실내/지역, NPC 밀도·성능은 별도 범위다. 보류한 혼잡도 시험은 그대로 보류한다.

실행: `C:\Users\PC\murim-rpg\godot\project.godot`을 열고 `res://prototypes/isometric/changsha.tscn`에서 **F6**. 로컬에는 적용되어 있다. 다른 작업본 업데이트:

```powershell
Set-Location C:\Users\PC\murim-rpg
git pull --ff-only origin main
```

연결 검사 재현은 별도 PowerShell에서 실행한다.

```powershell
Set-Location C:\Users\PC\murim-rpg
$env:APPDATA = Join-Path $env:TEMP ('murim-links-check-' + [guid]::NewGuid().ToString('N'))
& 'C:\Users\PC\AppData\Local\Python\pythoncore-3.14-64\python.exe' godot/tests/check_isometric_town_data.py
& 'C:\Users\PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --audio-driver Dummy --fixed-fps 60 --path godot --script res://tests/isometric_town_links.gd
```
