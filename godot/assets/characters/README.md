# 무창 주민 도트 시트

`wuchang-residents.png`는 이미지 생성 도구로 만든 새 투명8인 시트(1536×1024)다. 기존 `assets/characters.png`의 화풍·시점·비율을 참고했으며 기존 시트를 교체하지 않았다. 윗줄은 유백초·석대용·임정산·도삼랑, 아랫줄은 육정호·오덕수·정씨 할머니·주계복이다.

PNG 픽셀은 편집하지 않고 `data/wuchang_residents.json`의 영역을 AtlasTexture로 참조한다. 기존 주민 표시 높이132와 전신 안전 폭88 안에 맞추고 발 기준으로 정렬한다. 생성 직후 알파 채널을 읽어 영역만 측정했다. [인물·검사](../../../docs/characters/wuchang-civilians.md).
