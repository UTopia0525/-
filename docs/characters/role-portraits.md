# 산적·수적·낭인 전용 초상화

2026-10-26. 사용자 요청으로 산적·수적·낭인 대화용 그림을 제작해 기존 등장인물에 적용했다. 산적은 같은 대화에서 서로 다른 두 사람을 표현할 수 있도록2종으로 만들었다. 이4장은 주민용 기본18장에 넣지 않으며 주인공 그림도 변경하지 않는다.

| 그림 | 외형·복식 | 적용 인물 |
| --- | --- | --- |
| [산적1](../../godot/assets/portraits/archetypes/bandit.png) | 거친 수염, 갈색 두건·황토색 거친 옷·가죽 어깨끈 | 장사 길목 산적, 약초꾼 구출의 구칠, 청애채 후육 |
| [산적2](../../godot/assets/portraits/archetypes/bandit-sentry.png) | 길쭉한 얼굴, 도드라진 귀, 먹회색 옷·적갈색 깃 | 장사 산적 우두머리, 청애채 정괴 |
| [수적](../../godot/assets/portraits/archetypes/water-bandit.png) | 남색 두건, 물일에 맞춘 짧은 소매, 밧줄 띠와 작은 갈고리 | 0장 흑린채 수적 `pirate` |
| [낭인](../../godot/assets/portraits/archetypes/wanderer.png) | 피곤한 눈매·수염, 빛바랜 회녹색 여행복, 봇짐과 검 | 무창 객잔 시비의 떠돌이 무인 장만길 |

모두 이미지 생성 도구로 만든1024×1536 RGBA 원본이다. [원본 식별·해시](../../godot/assets/portraits/archetypes/manifest.json)를 기록하고 투명 채널을 확인했다. 원본 픽셀은 후처리하지 않았다. `portrait_framing.json`에서 주인공 기준 눈높이/얼굴 크기에 맞게 표시하고 기존 화자 강조·상대방 어둡게 처리·좌우 시선을 유지한다.

전용 이미지가 인물ID의 기존 공용 그림보다 우선한다. 따라서 기존 저장에서 같은 대화를 재개해도 새 그림을 사용한다. 대사·퀘스트 조건·전투 수치·보상과 탐험/전투 도트 캐릭터는 변경하지 않았다. 마운표 같은 주요 인물은 자신의 기존 전용 그림을 유지한다. 같은 대화의 인물별 그림 중복 방지 규칙도 유지한다.

## 실제 대화 적용 화면

- [장사 산적 토벌](../../godot/screenshots/role-bandit-dialogue.png)
- [0장 수적 등장](../../godot/screenshots/role-water-bandit-dialogue.png)
- [무창 객잔 장만길](../../godot/screenshots/role-wanderer-dialogue.png)
- [두 산적을 함께 표시](../../godot/screenshots/role-bandit-pair-dialogue.png) — 청애채 인물 등록을 확인하는 대화 표시 예시이며 이 캡처는 인물 등록 단계의 예시이며 이후 산촌·청애채 의뢰에서 실제 배치했다.

기존 `conversation_tools.gd`에서 실제0장/장사 이야기 대사와 약초꾼·객잔·청애채 인물을 통해 새 그림의 연결·중복 방지·대화 기록/과거 대화 저장 읽기를 확인한다. `basic_npc_portraits.gd`에서 기본18장 구성, 신규8인의 그림과 화자 강조를 확인한다. 캡처는 `capture_role_portraits.gd`로 실제 Godot 렌더러에서 출력한다. 배포용 데모/실행 파일은 만들지 않았다.
