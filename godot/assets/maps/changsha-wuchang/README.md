# 장사–무창 산길

배치1024×2560, 실제 월드4096×10240. 먼저 동쪽으로 이동한 뒤 북쪽으로 올라가는 NPC 없는 육로다.

`rock.png`는 이미지 생성 도구로 만든 원본 RGBA1536×1024 바위 그림이다. 픽셀 후처리는 하지 않았으며 크기·아틀라스 영역은 메타데이터와 Sprite2D로 적용한다. 수목은 기존 장사 투명 아틀라스를 공유한다. `ground.png`는 Godot로 렌더링한 지형만의 캐시이며 바위·나무·NPC가 포함되지 않는다.

`python godot/tools/build_mountain_road.py`로 배치를 재생성하고 `tools/bake_regional_ground.gd`를 Godot 렌더러로 실행해 지형 캐시를 갱신한다. [왕복·지도·저장·검사](../../../../docs/cities/changsha-wuchang-road.md).
