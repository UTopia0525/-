# 탐험 인물 비율과 이동

이동 속도를180에서360으로 올렸다. WASD·방향키 이동에 적용한다. 맵 클릭 이동과 자동 접근은 제거했으며 F로 대화·조사·포탈을 사용한다. 메뉴의 마우스 선택은 유지한다.

도시 주인공 높이는82에서140, 주민은82에서132로 키웠다. 좁은 0장 나루터·갑판에서는 인물 높이104를 사용한다. 원본 아틀라스를 그대로 사용하며 발 위치를 기준으로 확대한다. 전투·대화 초상화는 이번 변경 대상이 아니다.

`exploration_metrics.gd`에 주민 전신 영역, 발 충돌 반경16, 이름·의뢰 표식 간격을 모았다. 주민 안전 배치에도 확대된 영역을 적용한다. 카메라는 인물 높이를 고려해 중심을 맞추며 기존 가장자리 제한을 유지한다. 걷기는 도시 기준10프레임/초, 작은 인물은 보폭에 맞춰 재생 속도를 보정한다.

실제 실행 화면:

- [상점가](../../godot/screenshots/movement-scale-market.png)
- [관아 문](../../godot/screenshots/movement-scale-gate.png)
- [0장 나루터](../../godot/screenshots/movement-scale-dock.png)

검사: `tests/movement_scale.gd`는 키보드 이동 거리, 입력이 없을 때 정지, 설정창 정지, 구역별 크기를 확인한다. `city_collision.gd`, `layered_city.gd`, `camera.gd`, `adventure_features.gd`, `prologue.gd`로 충돌·문 가림·주민 접근·카메라·의뢰·0장 진행을 확인한다. 실행 명령과 데이터 격리는 [개발 안내](../../godot/README.md)를 따른다.
