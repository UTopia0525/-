# 산길·무창·총무당 미술 통일

2026-10-24. 장사의 `layered/ground.png`와 공용 건물 아틀라스를 미술 기준으로 삼아 전용 바닥3장과 투명 가구 아틀라스1장을 이미지 생성/편집 도구로 제작했다. 원본 PNG의 해상도/해시는 `assets/maps/regional-art-manifest.json`에 기록했다. 원본 PNG를 그대로 저장하며 잘라 쓰는 가구는 이미지 편집 대신 AtlasTexture 영역 메타데이터를 사용한다.

- 산길: 기존 동진→북상 경로를 유지하고 흙길·잔자갈·지피식물·양옆 암벽에 픽셀 질감을 추가했다. 나무50개·바위32개는 기존 독립 오브젝트다.
- 무창: 흙길의 수레 자국·풀 경계, 강물·강안, 무림맹과 관아의 풍화된 판석, 남쪽 논·밭을 보강했다. 건물·담장·문은 바닥에 포함하지 않고 관아 담장 보강 후224개 독립 오브젝트를 유지했다.
- 총무당: 목재 바닥·회벽·창호·돗자리의 재질을 보강하고 책상·문서장·대기석·병풍·기둥·등롱을 상세 미술로 교체했다. 배치된 가구11개는 각각 충돌/Y정렬을 유지한다. 새 NPC나 무공은 추가하지 않았다.

맵 크기·이동 속도·길 찾기·NPC 좌표·포탈·보상·저장 형식은 그대로다. 가구 아틀라스의 `source` 영역과 표시 여백(`content_rect`)만 새 그림에 맞춰 변경했다. 여백은 충돌 영역을 바꾸지 않고 전체 지도와 미니맵에도 동일하게 반영한다. 원본 이미지 해상도가 배치 좌표 크기와 달라도 미니맵의 건물과 바닥이 일치하도록 텍스처 샘플 좌표와 배치 좌표를 분리했다.

## 전체 모습과 실제 플레이

아래 전체 이미지는 원화가 아닌 **Godot가 실제 바닥과 독립 오브젝트를 합쳐 렌더링한 맵**이다. 전체 배치 확인용 캡처에는 NPC와 UI를 제외했다.

| 맵 | 전체 모습 | 플레이 화면 |
| --- | --- | --- |
| 산길 | [전체](../../godot/screenshots/overland-full-map.png) | [고갯길](../../godot/screenshots/overland-art-pass.png) |
| 무창 | [전체](../../godot/screenshots/wuchang-full-map.png) | [상점가](../../godot/screenshots/wuchang-art-market.png) |
| 총무당 | [전체](../../godot/screenshots/alliance-office-full-map.png) | [실내](../../godot/screenshots/alliance-office-interior.png) |

## 제작·검증

`wuchang_ground.gd`, `mountain_road_ground.gd`, `alliance_office_ground.gd`는 전용 원본 텍스처를 맵의 배치 크기에 맞춰 표시한다. 기존 도형 기반 생성기는 `tools/reference-ground-generators/`에 참고용으로 보관했다. 이전 bake 도구는 안내만 출력하며 새 원화를 덮어쓰지 않는다. 미술 수정은 이미지 편집 도구를 사용하고 동선은 layout.json에 맞춘다.

`tests/map_art.gd`는 실제 탐험·전체 지도·미니맵과 포탈의 연결을 검사한다. `overland_travel`, `wuchang_residents`, `alliance_office` 검사로 왕복 이동·충돌·대화/거래·저장 호환을 확인했다. 전체/플레이 캡처는 `tests/capture_map_art.gd`로 생성한다.
