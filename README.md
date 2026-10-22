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

## 모용세가

[가문 설정과 무공](docs/factions/murong.md) · [가주·소가주 소개](docs/characters/murong-family.md)

| 가주 · 모용경원 | 소가주 · 모용유안 |
|---|---|
| ![모용경원](assets/portraits/murong/gyeongwon.png) | ![모용유안](assets/portraits/murong/yuan.png) |

## 소림

[문파 설정과 무학](docs/factions/shaolin.md) · [주요 인물 설정](docs/characters/shaolin.md)

| 방장 · 법연 | 계율 장로 · 법엄 |
|---|---|
| ![법연](assets/portraits/shaolin/beopyeon.png) | ![법엄](assets/portraits/shaolin/beobeom.png) |

| 젊은 제자 · 혜담 | 태상방장 · 현진 |
|---|---|
| ![혜담](assets/portraits/shaolin/hyedam.png) | ![현진](assets/portraits/shaolin/hyeonjin.png) |

## 무당파

[문파 설정·장삼봉 전승·무학](docs/factions/wudang.md) · [주요 인물 설정](docs/characters/wudang.md)

| 장문인 · 무당검선 운허 | 젊은 제자 · 청윤 |
|---|---|
| ![운허](assets/portraits/wudang/unheo.png) | ![청윤](assets/portraits/wudang/cheongyun.png) |

## 화산파

[문파 설정과 무학](docs/factions/huashan.md) · [장문인·제자 설정](docs/characters/huashan.md)

| 장문인 · 진목 | 젊은 제자 · 소운 |
|---|---|
| ![진목](assets/portraits/huashan/jinmok.png) | ![소운](assets/portraits/huashan/soun.png) |

## 종남파

[문파 설정과 천하삼십육검](docs/factions/zhongnan.md) · [장문인·제자 설정](docs/characters/zhongnan.md)

| 장문인 · 정허 | 젊은 제자 · 담진 |
|---|---|
| ![정허](assets/portraits/zhongnan/jeongheo.png) | ![담진](assets/portraits/zhongnan/damjin.png) |

## 아미파

[문파 설정과 청련유장](docs/factions/emei.md) · [장문인·제자 설정](docs/characters/emei.md)

| 장문인 · 정연 사태 | 젊은 제자 · 묘은 |
|---|---|
| ![정연 사태](assets/portraits/emei/jeongyeon.png) | ![묘은](assets/portraits/emei/myoeun.png) |

## 청성파

[문파 초안과 청람검법](docs/factions/qingcheng.md) · [장문인·제자 설정](docs/characters/qingcheng.md)

| 장문인 · 통현 | 젊은 제자 · 지온 |
|---|---|
| ![통현](assets/portraits/qingcheng/tonghyeon.png) | ![지온](assets/portraits/qingcheng/jion.png) |

## 공동파

[문파 설정과 복마검법](docs/factions/kongtong.md) · [장문인·제자 설정](docs/characters/kongtong.md)

| 장문인 · 현석 | 젊은 제자 · 담호 |
|---|---|
| ![현석](assets/portraits/kongtong/hyeonseok.png) | ![담호](assets/portraits/kongtong/damho.png) |

## 곤륜파

[문파 설정·운룡검법·운룡십팔식](docs/factions/kunlun.md) · [장문인·여제자 설정](docs/characters/kunlun.md)

| 장문인 · 도겸 | 젊은 여제자 · 연하 |
|---|---|
| ![도겸](assets/portraits/kunlun/dogyeom.png) | ![연하](assets/portraits/kunlun/yeonha.png) |

## 점창파

[문파 설정과 사일검법](docs/factions/diancang.md) · [장문인·제자 설정](docs/characters/diancang.md)

| 장문인 · 명담 | 젊은 제자 · 윤서 |
|---|---|
| ![명담](assets/portraits/diancang/myeongdam.png) | ![윤서](assets/portraits/diancang/yunseo.png) |
