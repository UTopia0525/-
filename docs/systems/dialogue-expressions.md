# 대화 표정 — 기존 인물 전체

2026-10-30. 실제 게임에서 사용하는 초상화44종(일반 주민 기본18종 포함)에 웃음·분노·슬픔·놀람을 추가했다. 기본 표정은 기존 원본을 유지한다. 새 그림176개는 인물별2×2 투명 시트44장에 들어 있으며, 옛 포졸 원본 `story/constable.png`처럼 현재 사용하지 않는 그림은 대상에서 제외했다.

## 실제 화면

- [웃음](../../godot/screenshots/expression-dialogue-smile.png), [분노](../../godot/screenshots/expression-dialogue-angry.png), [슬픔](../../godot/screenshots/expression-dialogue-sad.png), [놀람](../../godot/screenshots/expression-dialogue-surprised.png)
- 기본/웃음/분노/슬픔/놀람 비교: [1](../../godot/screenshots/expressions-gallery-01.png), [2](../../godot/screenshots/expressions-gallery-02.png), [3](../../godot/screenshots/expressions-gallery-03.png), [4](../../godot/screenshots/expressions-gallery-04.png), [5](../../godot/screenshots/expressions-gallery-05.png), [6](../../godot/screenshots/expressions-gallery-06.png)

초상화 원본을 이미지 생성 참조로 제공해 얼굴·나이·복장·수염/흉터·장신구/소품·화풍을 유지했다. 원본 파일은 덮어쓰지 않고, 시트 원본을 그대로 보관해 Godot 셰이더에서 해당 칸을 선택한다. 생성 출처는 `assets/portraits/expressions/provenance.json`, 그림 연결은 `data/portrait_expressions.json`에 있다.

## 대사와 연결

`data/dialogue_expression_cues.json`은 인물ID와 정확한 대사를 묶은224개의 표정 지시를 담는다. 감사/환대는 웃음, 위협/분노는 찡그림, 표행의 상실과 산촌의 후회는 슬픔, 습격/뜻밖의 발견은 놀람을 사용한다. 나머지 대사는 기본 표정이다. ‘다치지 않았다’는 안도나 평범한 가족 안부를 부상/비극과 혼동하지 않도록 구분했다.

런타임에서 임의로 키워드를 추측하거나 표정을 무작위로 선택하지 않는다. 새 대사는 다음처럼 명시할 수 있다. 기존 `to`/`facing` 및 부제 형식도 유지한다.

```gdscript
["hero", "그 손부터 거두시오.", {"emotion":"angry"}]
["cy_eunsowol", "잠시 쉬어 가세요.", {"emotion":"smile", "emotions":{"hero":"surprised"}}]
```

말하지 않는 인물은 마지막 표정을 유지한 채 어두워진다. 새 대화는 표정을 초기화하고, 대화가 끝나면 표정 텍스처 캐시를 비워 전체44종을 계속 메모리에 보유하지 않는다. 공용 그림이 중복되어 다른 얼굴을 배정받은 인물도 실제 선택된 그림에 맞는 표정 시트를 쓴다. 얼굴 크기/눈높이와 대화 상대를 향한 좌우 반전은 기존 정규화 경로를 유지한다.

대사 내용·선택지·보상은 바꾸지 않았다. 현재 대화/거래/전투 중 수동 저장 금지는 유지하며, 과거 대화 저장을 읽을 때 표정 지시를 재현한다. 표정 필드가 없는 옛 대사/저장도 정상적으로 읽는다.

`tools/build_dialogue_expression_cues.py`로 대사 목록/연결 파일을 재생성할 수 있다. 새 인물 그림은 기존 그림을 참조해 네 표정을 제작한 뒤 registry에 등록하고 실제 대화/비교표에서 확인한다.

검사: `tests/portrait_expressions.gd`, 기존 `dialogue.gd`, `conversation_tools.gd`, `basic_npc_portraits.gd`, `paper_dialogue_live.gd`. 실제 캡처는 `tests/capture_expressions.gd`를 사용한다.
