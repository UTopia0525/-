# 저장소 사용과 정리 기록

## 빠르게 작업 시작하기

본게임 작업은 루트 `AGENTS.md`와 `docs/CLI_HANDOFF.md`를 읽고 `docs/README.md`에서 해당 기능만 고른다. 파일이 크다는 이유로 모든 원본을 읽거나 이미지를 열 필요는 없다. 문서의 수치보다 최근 코드가 다르면 관련 기능 문서를 함께 확인한다.

예시:

```sh
git status --short
rg -n "write_slot|can_save" godot/scripts/save_system.gd
rg -n "loadout" godot/scripts/player_progress.gd godot/scripts/player_menu.gd
rg --no-ignore -n "기본방어" docs/archive
```

`.rgignore`는 일반적인 `rg` 검색 범위만 줄인다. GitHub 파일 조회나 모든 도구의 자동 읽기를 차단하는 설정은 아니다. 제외 자료도 필요하면 명시적으로 읽을 수 있다.

## 원본과 생성물

| 자료 | 기준 파일 | 파생물·참고 자료 |
| --- | --- | --- |
| 본게임 실행 | `godot/scripts/`, `godot/data/` | `docs/systems/`와 기능별 문서 |
| 세계지도 | `world-map/world-data.json` | `python world-map/sync-data.py`로 HTML 내장 데이터 갱신 |
| 0장 대사 | `docs/story/chapter-00-dialogues.md` | `scripts/export_prologue_dialogue.py`가 Godot 대사 JSON 2개를 덮어씀. 원고 수정 시 출력 차이를 검토 |
| BGM | `godot/assets/music/source/` | MIDI/악보 JSON은 편집 원본, OGG는 실제 재생 파일. 자산 README와 합성 도구 참고 |
| 전투 배경 | `godot/assets/battle-deck.png` | 웹 데모 CSS도 같은 파일 사용 |
| 아이콘 아틀라스 | `godot/assets/icons/` | 검토 HTML도 같은 PNG 3장 사용 |
| 실행 화면 | `godot/screenshots/` | 문서용 기록. 관련 capture 스크립트로 갱신 |

원본과 파생물은 목적이 다르므로 일괄 삭제하지 않는다. Godot의 `*.uid`, 자산 `*.import`, 폰트 라이선스도 유지한다. `.godot/` 캐시·exports·Python 캐시·로컬 편집기 설정·비공개 메모 등은 ignore 규칙으로 새 추적을 방지한다. 이미 추적된 파일에는 ignore만으로 소급 적용되지 않는다.

## 2026-10-24 정리

기준 커밋 `8e31b454`, 추적 파일478개를 조사하고 관련 텍스트238개에서 경로 참조를 확인했다.

- 루트 README를 짧은 시작 화면으로 바꾸고 인물·초상화 목록은 `docs/REFERENCE_GALLERY.md`로 분리했다.
- Godot README는 현재 실행·조작·검증 안내로, CLI 인계는 최신 상태 요약으로 바꿨다.
- 이전 Godot README와 인계 전문은 `docs/archive/`에 보관하고 Markdown 상대 링크를 새 위치에 맞췄다.
- 작업별 소스·데이터·검사 색인과 루트 AGENTS를 추가했다. 과거의 고정 기본공격/3칸 편성/대화 중 저장 안내를 현재 인계에서 제거했다.
- 바이트 내용의 Git blob SHA가 같은 이미지 사본4개를 제거하고 모든 사용 경로를 본게임 원본으로 연결했다. 작업 폴더의 중복 파일 합계는 **10,159,682바이트(약9.69MiB)**다.
- 두 분기의 항구 화면은 현재 같은 이미지지만 캡처 스크립트가 분기별로 생성하므로 별도 기록 경로를 유지했다.
- 웹 데모와 아이콘 검토 화면은 저장소 전체의 상대 경로를 사용한다. 각 폴더만 따로 복사하지 않는다.
- 게임 로직·수치·대사·저장 형식·원본 자산 경로는 유지했다.

세 진입 문서의 본문은 정리 전42,042자에서5,040자로 약88% 줄었다(문자 수 기준). 과거 기록은 필요할 때 읽는다. 이는 기본 탐색·반복 읽기를 줄이기 위한 구조이며 실제 크레딧 사용량을 보장하지 않는다.

Git은 동일 blob을 이미 공유하므로 이번 사본 제거가 Git 객체 저장량을9.69MiB 줄인다는 뜻은 아니다. 기존 이력도 그대로 남는다. 과거 이력 재작성·강제 푸시는 하지 않았다.

## Git 동기화

웹과 CLI 작업은 시작 전에 `git status`로 로컬 변경을 확인하고 `git pull --ff-only`로 맞춘다. 끝나면 관련 파일만 커밋·푸시한다. 동시 작업은 기능별 브랜치로 나누면 충돌을 줄일 수 있다.

새 환경에서 과거 이력이 필요하지 않을 때는 다음처럼 한 브랜치의 최신 상태만 받을 수 있다. 명령은 아직 로컬에 없는 폴더에서 실행한다.

```sh
git clone --depth 1 --single-branch https://github.com/UTopia0525/-.git murim-rpg
```

런타임 이미지를 포함한 최신 파일은 여전히 내려받는다. 저장소 전송량과 모델이 읽는 텍스트량은 서로 다르다. 게임 작업용 자산을 빠뜨리는 무조건적인 sparse checkout이나 Git LFS 전환은 이번에 적용하지 않았다.

## 검증 범위

변경 문서의 상대 링크, 공유 이미지 경로, 아이콘 검토 JavaScript 문법, 삭제 파일의 텍스트 참조를 정적으로 확인했다. GitHub 연결로 작업했으며 로컬 `git clone`은 네트워크 제한으로 실패했다. 이 환경에 Godot 실행 파일이 없어 게임 실행·기존 Godot 검사·브라우저 렌더링은 재실행하지 못했다. 실행 검증 명령은 `godot/README.md`와 작업 색인을 따른다.
