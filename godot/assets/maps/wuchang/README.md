# 무창 지도 자산

`layout.json`은2048×1920 기준 좌표를 월드8192×7680에4배로 배치한다. 남문에서 시작하는 NPC 없는 지도 답사용이다. `alliance-hall.png`는 이번 작업에서 이미지 생성 도구로 만든 전용2층 전각 원본(1536×1024 RGBA)이며 파일의 픽셀은 후처리하지 않았다. 원본은 `/workspace/generated_images/`에도 남겼다. 나머지 구조물은 장사 투명 아틀라스와 열린 문을 공유한다.

지형은 `wuchang_ground.gd`, 독립 건물/충돌은 `wuchang_map.gd`와 공용 `city_scenery.gd`, 답사·지도는 `wuchang_preview.gd`가 담당한다. 건물·담장을 바닥 이미지에 굽지 않는다. 배치 재생성은 저장소 루트에서 `python godot/tools/build_wuchang_layout.py`.

[배치·실행·검증](../../../../docs/cities/wuchang.md). 본편 이동과 NPC는 사용자 지도 승인 뒤 구현한다.

남쪽 농촌을 덧붙였으며 기존 성내 건물의 좌표·크기는 유지했다. 농촌의 작물 구역은 지형 그림과 `terrain_blockers`를 함께 관리한다. F5 본게임의 민간 주민은 `data/wuchang_residents.json`으로 별도 배치한다. 포탈은 남쪽 농촌 끝에 있다.
