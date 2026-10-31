# 남경 · 황궁 철거와 성 밖 농촌

2026-10-31 후속 사용자 요청을 반영한 현재 배치다. 이전 [세 도시 성곽](three-city-fortifications.md)의 남경 황궁 부분을 대체한다. 장사·무창 성곽은 그대로다.

![남경 전체 지도](../../godot/screenshots/nanjing-country-full.png)

북쪽 궁전 지붕·궁성문·주칠 벽과 궁전 전용 충돌을 없애고, 북서 성문 동쪽부터 동북 모서리까지 회색 석조 성곽을 이어 붙였다. 중앙 대로는 북쪽 성벽 앞에서 끝난다. 북서쪽 남궁세가 방면 성문은 계속 드나들 수 있다.

성 밖의 갈색 여백에는 논·채소밭13구획, 농가7동·농업 창고1동과 풀밭·흙길·앞마당을 배치했다. 논밭은 폭과 모서리를 조금씩 달리하고, 흙길은 기존 북서 성문 및 서쪽 입구에 연결한다. 동쪽 성벽 바깥에는 작은 농가와 길게 이어지는 논을 배치했다. 강 건너 남서쪽 좁은 땅에는 경관용 논밭만 두었다. 물길/도시 내부를 밭으로 덮지 않으며 지도 가장자리까지 풀밭을 이어 남은 단색 띠를 줄였다.

건물은 승인된 장사 `painted/living.png`의 소박한 농가·민가·창고를 비율 보존해 재사용한다. 새 논/채소/풀/흙 재질은 소주 논과 장사 미술을 참조한 생성 원본 `capital/rural-materials.png`이며 원본을 수정하지 않았다. 출처·해시는 `capital/rural-art-manifest.json`에 기록한다. 바닥 의미 마스크는 Godot 실행 시 생성하며, 그림·건물 충돌·Y정렬은 분리한다.

| 확인 화면 | 링크 |
| --- | --- |
| 성곽과 농촌 전경 | [넓은 시야](../../godot/screenshots/nanjing-country-north-wide.png) |
| 실제 플레이 카메라 | [북쪽 농가](../../godot/screenshots/nanjing-country-north-farms.png) · [동쪽 논길](../../godot/screenshots/nanjing-country-east-farms.png) · [서쪽 농가](../../godot/screenshots/nanjing-country-west-farm.png) · [북쪽 성벽](../../godot/screenshots/nanjing-country-north-wall.png) |

전경은 구조 확인용0.45배, 나머지는 기본0.8배 카메라다. 전체 지도/미니맵 바닥 캐시도 현재 지형으로 재생성한다. 위 전체 지도는 건물/바닥을 함께 렌더한 화면이며 NPC 위치도는 아니다.

## 동작과 검증

세계7424×5632·layout_version3·기존 중앙 대로·진회하 세 다리·출입 포탈/도착점은 유지한다. 기존 주민·의뢰·보상·거래·분기·저장 형식은 바꾸지 않는다. 새 NPC/의뢰/농가 내부는 추가하지 않는다. 구version2/1 저장의 기존 위치 이행도 유지한다.

분리된 XDG 저장 폴더/Godot4.6.3에서 다음 검사를 통과했다.

- `nanjing_countryside.gd`: 황궁 오브젝트 제거, 새 농가8곳 앞 통행·경로, 북쪽 연속 벽 충돌, 외곽 흙길과 모든 포탈 접근.
- `city_fortifications.gd`: 세 도시 NPC/포탈 접근·전신 겹침, 성문 실제 키보드 통행, 남경 중앙 대로·다리, version2/3 저장 복원.
- `nanjing_layout.gd`: 남경 다리/강·기존 주민 접근, 건물 비율/회전/부지, 지도 버전.
- `nanjing_market_slice.gd`: 기존 시장 건물·통행·거래와 재질 적용.

`capture_nanjing_countryside.gd`로 전체 지도와 실제 카메라/바닥 캐시를 재생성한다. 캐시를 Godot에서 다시 가져온 뒤 재촬영하면 미니맵도 현재 바닥을 표시한다. 일부 검사 종료 때 기존 ObjectDB/리소스 정리 경고가 남으나 위 기능 검사 실패는 없다. Windows GPU 성능을 측정한 결과는 아니다.
