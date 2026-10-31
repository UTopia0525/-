# 시내 돌 포장 공통 기준

2026-10-31. 남경 시내의 포장 기준을 나머지 도시 장사·무창·소주·항주에도 적용했다. 기존 시장 재질 `nanjing/market-slice/materials.png`의 회색 돌·밝은 판석을 월드 좌표로 반복해 사용한다. 새 그림이나 건물/바닥 원본 PNG 수정 없이 실행 시 포장 마스크와 셰이더만 바꿨다. 기존의 그려진 명암/건물 그림자·시점·캐릭터 비율을 유지한다.

| 도시 | 구성 | 전체 지도 | 실제 플레이 |
| --- | --- | --- | --- |
| 장사 | 절제한 판석 마당, 회색 돌길 | [전체](../../godot/screenshots/changsha-stone-full.png) | [시내](../../godot/screenshots/changsha-stone-street.png) · [성 밖](../../godot/screenshots/changsha-stone-outside.png) |
| 무창 | 실용적인 판석 마당, 회색 도로·무림맹 구내 | [전체](../../godot/screenshots/wuchang-stone-full.png) | [시내](../../godot/screenshots/wuchang-stone-street.png) · [성 밖](../../godot/screenshots/wuchang-stone-outside.png) |
| 소주 | 밝은 판석 생활 구역, 회색 돌길 | [전체](../../godot/screenshots/suzhou-stone-full.png) | [시내](../../godot/screenshots/suzhou-stone-street.png) · [운하](../../godot/screenshots/suzhou-stone-canal.png) |
| 항주 | 밝은 판석·돌길, 흑도 골목은 어둡고 낡은 포장 | [전체](../../godot/screenshots/hangzhou-stone-full.png) | [시장](../../godot/screenshots/hangzhou-stone-market.png) · [골목](../../godot/screenshots/hangzhou-stone-slums.png) · [성 밖](../../godot/screenshots/hangzhou-stone-outside.png) |

장사 동쪽 농지와 무창 남쪽 농촌, 항주 북문 바깥 흙길은 원래 그림을 유지한다. 소주는 성곽 없는 기존 도시이므로 양쪽 생활 구역을 기준으로 포장하고 운하·다리·농지·곡물 건조장을 구분한다. 항주의 목재 하역장과 수문/수면도 보존한다. 남경의 기존 시내 포장 및 최근 외곽 재배치는 변경하지 않는다. 세가 장원·산길·실내는 도시 시내 포장 작업의 대상이 아니다.

## 구현·검증

- 장사: `changsha_painted_ground.gd`의 성 안 마스크와 기존 회색 돌/판석을 사용한다. 기존 시외 문턱과 농지는 포장 범위 밖이다.
- 무창: `wuchang_painted_ground.gd`가 성 안 마당을 판석으로 채우고 도로는 같은 경계로 잘라 포장한다. 바깥 흙길 처리는 유지한다.
- 소주: `suzhou_painted_ground.gd`/셰이더에서 생활 구역의 흙을 판석으로 교체한다. 곡물 작업장과 논·수로 분류는 유지한다.
- 항주: `hangzhou_painted.gdshader`의 시내 범위에서만 흙 재질을 판석으로 대체한다. 기존 회색 도로·밝은 취월루 앞·낡은 골목의 명도 차이는 유지한다.

건물·NPC·의뢰/상점·포탈·충돌·세계 크기·저장 버전은 변경하지 않는다. 실제 게임 경로의 `city_fortifications.gd`, `suzhou_maps.gd`, `hangzhou_fortifications.gd`를 분리된 XDG 사용자 폴더/Godot4.6.3에서 실행해 모두 통과했다. 기존 ObjectDB/리소스 종료 정리 경고와 기능 검사 실패는 구분한다.

`capture_city_stone.gd`는 도시별 전체 지도, 미니맵 바닥 캐시와 기본0.8배 실제 플레이 화면을 생성한다. 바닥 캐시를 다시 가져온 뒤 `-- --views-only`로 재촬영하면 최신 미니맵도 함께 확인할 수 있다. 이전 `*-painted-*`/`*-fortified-*` 화면은 작업 당시 기록이며 위 `*-stone-*`이 현재 결과다.

전후 전체 지도 픽셀 비교로 장사 동쪽 농지/서쪽 수면, 무창 남쪽 농촌/서쪽 수면, 소주 운하/논/곡물 작업장, 항주 북문 밖 접근로/서쪽 수면이 동일함을 확인했다. 항주 부두 내부 목재는 보존하고 연결 통로의 흙 혼합분만 포장으로 바뀐다.
