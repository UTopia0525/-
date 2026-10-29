# 명초 무협 RPG

1390년경을 배경으로 하는 탑다운 탐험·1인 턴제 전투 RPG입니다. 현재 개발 대상은 **[Godot 본게임](godot/README.md)**입니다.

## 실행

Godot 4.6 이상 Standard에서 `godot/project.godot`을 열고 F5를 누릅니다. 0장 전체 분기, 장사 자유 탐험·거래·의뢰9종, Q 의뢰 일지·F2 도움말·L 교전 기록, 조건부 산적 토벌을 구현했습니다. 전체 게임은 개발 중입니다.

## 별도 3D 탐험 테스트

[항주 · 등불과 물길](godot-3d-hangzhou/README.md)은 기존 본게임과 분리된3인칭3D 테스트입니다. Godot에서 `godot-3d-hangzhou/project.godot`를 별도로 가져와 F5로 실행합니다. 취월루·수변 야시장·다리·유람선과 청색 복장의 도원 모델을 구현했으며 NPC/전투/퀘스트는 없습니다.

## 개발 이어가기

1. [현재 상태와 작업 인계](docs/CLI_HANDOFF.md)
2. [작업별 문서·코드·검사 색인](docs/README.md)
3. [공통 작업 안내](AGENTS.md) · [게임 콘텐츠 규칙](godot/AGENTS.md)

현재 인계와 요청에 해당하는 파일부터 읽으면 됩니다.

| 위치 | 용도 |
| --- | --- |
| `godot/` | 본게임 코드·데이터·실행 자산·검사 |
| `godot-3d-hangzhou/` | 독립 항주3D 탐험 테스트 |
| `docs/` | 기능별 기획·구현 설명·세계관 |
| `assets/portraits/` | 세계관 인물의 초상화 원본 |
| `world-map/` | 독립 세계지도 도구 |
| `demo/` | 이전 브라우저 데모 |
| `prototypes/` | 초기 화면 시안 |
| `scripts/`, `tools/` | 대사 내보내기·음악 합성·자산 점검 |

## 설정과 참고 자료

- [세력 색인](docs/factions.md) · [통합 설정집](docs/factions-overview.md) · [시대 설정](docs/world-setting.md)
- [인물·초상화 갤러리](docs/REFERENCE_GALLERY.md)
- [세계지도](world-map/index.html): 브라우저에서 열기. 데이터 수정 후 `python world-map/sync-data.py`.
- [이전 웹 데모 실행](demo/README.md): 저장소 전체를 내려받고 `demo/index.html` 열기.
- [정리 내역과 저장소 사용법](docs/REPOSITORY_GUIDE.md)
