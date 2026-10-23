# 명초 무협 RPG

**[Godot 4 프로젝트 · 실행 안내와 실제 화면](godot/README.md)** — 침몰·귀물/구조 선택·보수·장사 항구까지 진행하는 0장 버전. `godot/project.godot`을 Godot에서 열고 F5로 실행한다.

**[0장 플레이 데모 실행 안내](demo/README.md)** — 저장소를 내려받은 뒤 `demo/index.html`을 브라우저에서 열면 된다. GitHub 파일 미리보기에서는 실행되지 않는다.

`world-map/index.html`을 브라우저에서 열면 된다. 외부 라이브러리·설치·서버 없이 작동한다.

- 1390년경 주요 도시 20곳과 구파일방·오대세가 거점 15곳, 녹림 핵심 산채 3곳과 장강 핵심 수채 1곳, 항주 흑도방 총본부
- 도시·문파·세가 선택 시 위치와 설정 근거 표시
- 육로·수로·구파일방·오대세가·녹림 산채·장강 수채·도시 사파 표시 전환, 확대·축소, 드래그 이동
- 데이터: `world-map/world-data.json` (수정 후 `python world-map/sync-data.py` 실행)
- 무협 세력 선정 및 개별 컨셉 색인: `docs/factions.md`
- 남궁세가 확정 컨셉: `docs/factions/namgung.md`
- 시대 설정·고증 한계: `docs/world-setting.md`

전체 지도 설계와 함께, 출항 전 대화·도트 탐험·승선·첫 턴제 전투까지 플레이하는 [0장 데모](demo/README.md)가 구현되어 있다. 전체 게임과 이후 스토리는 아직 미구현이다.

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

## 개방

[방회 설정·결개 계급·무학](docs/factions/beggars.md) · [방주·방도 설정](docs/characters/beggars.md)

| 방주 · 구만복 | 젊은 방도 · 이소칠 |
|---|---|
| ![구만복](assets/portraits/beggars/gumanbok.png) | ![이소칠](assets/portraits/beggars/leesochil.png) |

전체 세력과 주요 인물 요약: [구파일방·오대세가 통합 설정집](docs/factions-overview.md).

## 녹림삼십육채

[연합 설정·세 산채 위치·독문 외공](docs/factions/greenwood.md) · [총채주 후보 세 명](docs/characters/greenwood.md)

세계관에는 36채가 존재하지만 지도에는 흑석채·적송채·청애채 세 곳만 배치했다. 지도에서 ‘녹림 핵심 산채’ 버튼으로 표시를 전환하고 산채를 선택하면 채주와 무공을 볼 수 있다.

| 흑석채 · 곽철산 | 적송채 · 연적하 | 청애채 · 마운표 |
|---|---|---|
| ![곽철산](assets/portraits/greenwood/gwatcheolsan.png) | ![연적하](assets/portraits/greenwood/yeonjeokha.png) | ![마운표](assets/portraits/greenwood/maunpyo.png) |

## 장강수로십팔채

[수로채 설정과 무학](docs/factions/waterbandits.md) · [흑린채 채주 염문악](docs/characters/waterbandits.md)

세계관에는 18채가 있지만 지도에는 동정호 인근 흑린채 한 곳만 배치했다. ‘장강 핵심 수채’ 버튼과 청색 마름모로 구별한다.

![염문악](assets/portraits/waterbandits/yeommunak.png)

## 흑도방

[조직 설정과 추가 채택 후보](docs/factions/blackguild.md) · [방주 위중량](docs/characters/blackguild.md)

전국의 여러 작은 흑도 조직을 총괄하고 금전적 이득을 최우선으로 삼는 조직. 총본부는 항주로 확정했다. 추가 운영 설정은 미정이다.

![위중량](assets/portraits/blackguild/wijungnyang.png)

추가 세력 제안: [무영각·적월문·하오문](docs/factions/heterodox-candidates.md). 적월문·중립 하오문은 채택했고, 무영각은 채택 전 후보이다.

## 적월문

[문파 설정과 적월연환도](docs/factions/redmoon.md) · [문주·아들 설정](docs/characters/redmoon.md)

민초를 해치지 않고 강함을 추구하는 독립 사파 도법 명문. 아들의 후계 지위와 거점 위치는 미정이다.

| 문주 · 한무진 | 문주의 아들 · 한승재 |
|---|---|
| ![한무진](assets/portraits/redmoon/hanmujin.png) | ![한승재](assets/portraits/redmoon/hanseungjae.png) |

## 하오문

[중립 생활·정보 문파 설정](docs/factions/haomun.md). 공개 가능한 조직 정보만 기록한다. 위치와 구체적인 운영 규칙은 미정이다.

## 예인 인물

[중원제일미 은소월 — 공개 소개](docs/characters/eunsowol.md)

![은소월](assets/portraits/performers/eunsowol.png)

## CLI에서 작업 이어가기

현재 구현 상태와 최신 전투·0장 설정은 [CLI 인계 문서](docs/CLI_HANDOFF.md)를 먼저 확인한다.

- [장사 자유 탐험 도시 맵 — 전체 지도와 이용 안내](godot/assets/maps/changsha/README.md)

[0장 전체 대화 원고 — 가라앉은 약속](docs/story/chapter-00-dialogues.md): 출항·습격·침몰·귀물/구조 선택과 두 경로의 후회, 표국 해체·인도/실패 보고·장사 입성을 정리했다. 귀물 인도 보수는 3,000문이다. 해당 대사와 분기는 Godot에 연결했으며 [구현 안내](docs/story/chapter-00-implementation.md)를 따른다.

[1장 도입 연결](docs/story/chapter-01-intro.md): 0장 직후 포목상 대화 → 첫 옷감 의뢰 수락 → 중앙 ‘1장’ 표시 → 조작 재개. 1장 제목은 미정이다.

[설정·수동 저장 슬롯 10개](docs/systems/save-slots.md): 대화·분기 직전·선택 이후 등 여러 시점을 남기고 돌아올 수 있다.

[내기 전투 자원](docs/systems/inner-qi.md): 최대 500, 전투 시작량·턴 회복량은 내공과 동일하며 향후 공격/방어 기술의 비용으로 사용한다.

[상위 초급 공격 무공10종](docs/martial-arts/basic-attacks.md): 피해 식·내기 소비·학습 조건. 삼재검법은 내기10으로 확정했다. 신규 무공의 획득 방법은 미정이다.
