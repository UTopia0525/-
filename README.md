# 명초 무협 RPG — 세계 지도 초안

`world-map/index.html`을 브라우저에서 열면 된다. 외부 라이브러리·설치·서버 없이 작동한다.

- 1390년경 주요 도시 20곳과 구파일방·오대세가 거점 15곳
- 도시·문파·세가 선택 시 위치와 설정 근거 표시
- 육로·수로·구파일방·오대세가 표시 전환, 확대·축소, 드래그 이동
- 데이터: `world-map/world-data.json` (수정 후 `python world-map/sync-data.py` 실행)
- 무협 세력 선정 및 개별 컨셉 색인: `docs/factions.md`
- 남궁세가 확정 컨셉: `docs/factions/namgung.md`
- 시대 설정·고증 한계: `docs/world-setting.md`

현재는 전체 지도 설계이며, 실제 도트 탐험·전투·스토리는 미구현이다.

남궁세가 주요 인물과 대사 초안: [인물 설정](docs/characters/namgung-family.md). 초상화 원본은 `assets/portraits/namgung/`에 보관한다.

## 이미지 보기

GitHub에서 아래 링크를 누르면 각 PNG를 확인하고 다운로드할 수 있다.

- [전체 지도](docs/world-map-preview.png)
- [남궁정천 — 가주](assets/portraits/namgung/jeongcheon.png)
- [남궁서진 — 소가주](assets/portraits/namgung/seojin.png)
- [남궁도윤 — 차남](assets/portraits/namgung/doyun.png)
- [남궁연서 — 막내딸](assets/portraits/namgung/yeonseo.png)

### 전체 지도

![명초 강호도](docs/world-map-preview.png)

### 남궁세가

| 가주 · 남궁정천 | 소가주 · 남궁서진 |
|---|---|
| ![남궁정천](assets/portraits/namgung/jeongcheon.png) | ![남궁서진](assets/portraits/namgung/seojin.png) |

| 차남 · 남궁도윤 | 막내딸 · 남궁연서 |
|---|---|
| ![남궁도윤](assets/portraits/namgung/doyun.png) | ![남궁연서](assets/portraits/namgung/yeonseo.png) |

세력별 인물·초상화 제작 기준: [제작 원칙](docs/characters/creation-guidelines.md). 전투 스탯은 전투 시스템 확정 이후 일괄 부여한다.

## 하북팽가

[가문 설정](docs/factions/peng.md) · [가주·소가주 설정](docs/characters/peng-family.md)

| 가주 · 팽진산 | 소가주 · 팽무열 |
|---|---|
| ![팽진산](assets/portraits/peng/jinsan.png) | ![팽무열](assets/portraits/peng/muyeol.png) |

## 제갈세가

[가문 설정과 창작 무공](docs/factions/zhuge.md) · [주요 인물 설정](docs/characters/zhuge-family.md)

| 가주 · 제갈문겸 | 소가주 · 제갈윤 | 정파제일화 · 제갈설하 |
|---|---|---|
| ![제갈문겸](assets/portraits/zhuge/mungyeom.png) | ![제갈윤](assets/portraits/zhuge/yun.png) | ![제갈설하](assets/portraits/zhuge/seolha.png) |

## 사천당가

[가문 설정과 무공](docs/factions/tang.md) · [가주·장녀·소가주 설정](docs/characters/tang-family.md)

| 가주 · 당겸 | 장녀 · 당서령 | 소가주 · 당윤재 |
|---|---|---|
| ![당겸](assets/portraits/tang/gyeom.png) | ![당서령](assets/portraits/tang/seoryeong.png) | ![당윤재](assets/portraits/tang/yunjae.png) |
