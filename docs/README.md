# 작업별 색인

3D 실험: [항주3인칭 탐험 프로젝트·실행/조작/검사](../godot-3d-hangzhou/README.md). 기존2D 게임과 별도로 연다.

고유 전투 인물: [전투 도트4종·자세/효과·실제 비교표](characters/dedicated-battle-visuals.md).

흑도방 후속: [등불 밖의 셈·운하 창고/본당·양 노선·대화 원고](quests/blackguild-story.md).

중급 영약 구현: [하오문 호의도20 이상·취월루 점소이 안내·항주 두청하 판매/아이콘/복용](systems/mid-grade-elixirs.md). 제안 기록의 자연물은 미채택.

0장 보수: [귀물 인도500문·옛 수령 저장 유지](story/chapter-00-implementation.md#보수500문-변경).

최신 유안/탁문호: [일류250·300 조정/150쌍 비교](systems/yuan-tak-balance.md).

최신 마운표: [절정 총합310·체력875·80쌍 비교](systems/maunpyo-peak.md).

현재 체력/밸런스: [근력·근골 공통 체력 공식과306쌍 전투 비교](systems/health-growth.md).

인물 미술 작업: [모델과 관계없이 유지하는 화풍·비율·실제 표시 검수 기준](characters/art-consistency.md).

전체 세계지도: [실제 구현 지역을 굵게 표시한 현황 지도](world-map-progress.png) · [확대·선택 가능한 HTML](world-map-progress.html). 도시/거점 구현과0장 선상 전투만 있는 흑린채를 구분했다.

최신 변경: [주요 전투 사망·타이틀 복귀](systems/combat-death.md), [산촌·청애채 선택 의뢰](quests/qingya-village.md), [BGM 반복 재생 유지](systems/bgm-loop.md), [산길 이동 단축·발 교차 보행](systems/short-road-and-stride.md), [작은 A안 HUD](ui/compact-a.md). 이전 비교 시안과 검토는 당시 기록이다.

남경: [처음 시안 기준 맵·실제 화면](cities/nanjing.md), [구휼 의뢰·육소전·실제 화면](quests/nanjing-relief.md) — 구현 완료. [이야기 원안](story/nanjing-outline.md).

시안 검토: [남경 전체 이미지·기본 NPC12명·세력 인물 후보](cities/nanjing-preview.md) — 구현 전의 검토용 이미지. 실제 동작은 위 구현 문서를 따른다.

현재 상태는 [CLI 인계](CLI_HANDOFF.md), 실행은 [Godot 안내](../godot/README.md)를 참고한다. 아래 경로는 저장소 루트 기준이다. 문서와 관련 소스만 먼저 읽고 필요한 검사를 선택한다.

| 작업 | 설명 | 주요 코드·데이터 | 기존 검사 (`godot/tests/`) |
| --- | --- | --- | --- |
| 소주 일반 의뢰5종 | [진행·전투·보상](quests/suzhou.md), [원고](quests/suzhou-dialogues.md) | `data/suzhou_quests.json`, `scripts/suzhou_quests.gd`, `suzhou_errand.gd` | `suzhou_quests.gd`, `suzhou_quest_balance.gd` |
| 소주 일반 주민14명 | [이름·관계·배치·생활 대화](characters/suzhou-residents.md) | `data/suzhou_residents.json`, `data/service_npc_portraits.json` | `suzhou_residents.gd`, `suzhou_maps.gd` |
| 소주·남경 동쪽 산길 | [구역·실제 전체 맵·왕복 이동](cities/suzhou.md) | `scripts/suzhou_map.gd`, `assets/maps/suzhou/layout.json`, `assets/maps/nanjing-suzhou/layout.json` | `suzhou_maps.gd`, `capture_suzhou.gd` |
| 0장·분기 | [진행](story/chapter-00-implementation.md), [원고](story/chapter-00-dialogues.md) | `scripts/prologue.gd`, `data/prologue_dialogues.json` | `prologue.gd`, `chapter_one.gd` |
| 도입 의뢰3종 | [진행·보상](quests/trade-intro.md) | `scripts/trade_intro.gd`, `data/trade_intro.json` | `onboarding_menus.gd` |
| 일반 의뢰6종 | [실제 진행·표식](systems/adventure-usability.md), [목록](quests/changsha.md), [흐름](quests/quest-flow.md), [원고](quests/changsha-dialogues.md) | `data/normal_quests.json`, `scripts/ordinary_quests.gd`, `quest_navigation.gd` | `adventure_features.gd`, `quest_navigation.gd` |
| 세력 호의도 | [명성과의 구분·저장](systems/faction-favor.md) | `scripts/player_progress.gd`, `player_menu.gd` | `faction_favor.gd`, `impostor_quest.gd`, `saves.gd` |
| 무창 무림맹 사칭 사건 | [전수 후 활성화·감사·보상](quests/wuchang-impostor.md) | `scripts/impostor_quest.gd`, `data/wuchang_impostor_quest.json` | `impostor_quest.gd`, `capture_impostor_quest.gd` |
| 무창 객잔 시비 | [진행·분기·원고](quests/wuchang-inn.md) | `scripts/inn_quest.gd`, `data/wuchang_inn_quest.json` | `inn_quest.gd`, `capture_inn_quest.gd` |
| 무창 대련·조식수원공 | [진행·전수·제한](quests/wuchang-duel-proposal.md) | `scripts/duel_quest.gd`, `data/wuchang_duel_quest.json`, `data/support_martial_arts.json`, `scripts/combat_actions.gd` | `duel_quest.gd`, `josik_suwon.gd` |
| 무창 문패·세곡 의뢰 | [진행·보상·동시 수행](quests/wuchang-last-two.md) | `scripts/plaque_quest.gd`, `grain_quest.gd`, `data/wuchang_plaque_quest.json`, `wuchang_grain_quest.json` | `last_wuchang_quests.gd`, `artisan_quest.gd` |
| NPC 배치 지도 | [장사/무창 번호 지도·명단](cities/npc-placement-maps.md) | `tests/capture_npc_maps.gd`, `npc_map_sheet.gd` | 실제 NPC 좌표/주민 수를 출력 도구에서 확인 |
| 무창 품삯 의뢰 | [진행·신규 주민·보상](quests/wuchang-wages.md) | `scripts/wages_quest.gd`, `work_board.gd`, `data/wuchang_wages_quest.json` | `wages_quest.gd`, `artisan_quest.gd`, `impostor_quest.gd` |
| 무창 장인의 이름값 | [진행·원고·검증](quests/wuchang-artisan.md) | `scripts/artisan_quest.gd`, `data/wuchang_artisan_quest.json` | `artisan_quest.gd` |
| 무창 약초꾼 의뢰 | [진행·원고·난이도](quests/wuchang-herbalist.md) | `scripts/herbalist_quest.gd`, `data/wuchang_herbalist_quest.json` | `herbalist_quest.gd` |
| 도시 간 육로 | [산길·출입·지도·저장](cities/changsha-wuchang-road.md) | `scripts/overland_travel.gd`, `mountain_road_map.gd`, `assets/maps/changsha-wuchang/layout.json` | `overland_travel.gd`, `capture_overland.gd` |
| 송지겸 전용 초상화 | [인물·그림·세 장면](characters/song-jigyeom.md) | `scripts/dialogue_portraits.gd`, `data/portrait_framing.json` | `dialogue.gd`, `basic_npc_portraits.gd`, `capture_song_portrait.gd` |
| 무림맹 초대·중급 전수 메인 | [실제 진행·대사·검증](story/alliance-main-story.md) | `scripts/alliance_story.gd`, `data/alliance_story.json`, `alliance_visit.gd` | `alliance_story.gd`, `bandit_story.gd`, `alliance_visit.gd` |
| 무림맹 경비·총관·교관 | [인물](characters/alliance-headquarters.md), [출입·진행 구분](story/alliance-visit-foundation.md) | `data/alliance_characters.json`, `scripts/alliance_visit.gd` | `alliance_visit.gd`, `capture_alliance_visit.gd` |
| 무창 민간 주민 | [8인 설정·대사·그림](characters/wuchang-civilians.md) | `data/wuchang_residents.json`, `scripts/exploration.gd`, `dialogue_portraits.gd` | `wuchang_residents.gd`, `capture_wuchang_residents.gd` |
| 맵 미술 통일 | [산길·무창·총무당](cities/regional-map-art.md) | `scripts/*ground.gd`, `assets/maps/*/ground.png` | `map_art.gd`, `capture_map_art.gd` |
| 산촌·청애채 의뢰 | [진행·보상·폐허·검사](quests/qingya-village.md) | `scripts/qingya_quest.gd`, `qingya_map.gd`, `data/qingya_quest.json` | `qingya_quest.gd`, `qingya_balance.gd` |
| 산적·수적·낭인 그림 | [전용4장·기존 적용처](characters/role-portraits.md) | `scripts/dialogue_portraits.gd`, `herbalist_quest.gd`, `inn_quest.gd` | `conversation_tools.gd`, `basic_npc_portraits.gd` |
| 산촌·청애채 인물 | [8인 설정·이미지 배정](characters/qingya-cast.md) | `data/qingya_characters.json`, `dialogue_portraits.gd` | `basic_npc_portraits.gd` |
| 산촌·청애채 디자인 | [2개 맵 구도·확정 분기](cities/qingya-maps.md) | 시안 보존, 본게임 구현은 위 의뢰 행 참고 | 후속 맵 구현 시 검사 |
| 무창·무림맹 지도 | [배치·답사·범위](cities/wuchang.md), [조직 설정](factions/murim-alliance.md) | `scripts/wuchang_map.gd`, `wuchang_preview.gd`, `wuchang_ground.gd`, `assets/maps/wuchang/layout.json` | `wuchang.gd`, `capture_wuchang.gd` |
| 장사 주민 정리·이름 | [의뢰 관련11인 설정](characters/changsha-quest-residents.md) | `assets/maps/changsha/layout.json`, `scripts/ordinary_quests.gd`, `main.gd` | `changsha_residents.gd`, `quest_navigation.gd`, `adventure_features.gd` |
| 도시·충돌 | [인물 비율·이동](systems/exploration-scale.md), [도시 기준](cities/city-standards.md), [현재 장사·오브젝트](systems/layered-city-and-conversation.md) | `scripts/exploration.gd`, `city_scenery.gd`, `assets/maps/changsha/layout.json` | `layered_city.gd`, `city_collision.gd`, `changsha.gd`, `city_services.gd` |
| 거래·I/K·성장 | [거래](systems/city-trading.md), [정비창](systems/player-menus.md), [K 행동력·범위 UI](ui/k-tactics.md) | `scripts/player_progress.gd`, `city_service.gd`, `player_menu.gd` | `trading.gd`, `onboarding_menus.gd` |
| 사망·전투 결과 | [기본 사망/기존 예외/타이틀 복귀](systems/combat-death.md) | `scripts/combat_outcome.gd`, `death_screen.gd`, `main.gd` | `death_flow.gd` |
| 조절형 전투 실험실 | [사용법·화면·가정](../prototypes/grid-initiative-simulation/README.md), [후속 행동/방어 기획](systems/grid-action-timing.md) | `prototypes/grid-initiative-simulation/engine.js`, `editor.js` | `scripts/test_grid_simulator.cjs`, `export_grid_simulator_catalog.gd`, `scripts/capture_grid_initiative_replay.mjs` |
| 적 밸런스·대응 AI | [9전투 수치·140조건](systems/encounter-balance.md) | `scripts/grid_tactical_ai.gd`, `data/tutorial_enemy.json`, 조우 데이터 | `encounter_balance.gd`, `grid_ai_reactions.gd`, `grid_story_integration.gd` |
| 가변 격자 전투 | [실제 화면·행동력·전장 설정](systems/grid-combat.md), [전투 미술·기본 동작](ui/premium-battle.md) | `scripts/grid_combat.gd`, `battle_field.gd`, `grid_battle.gd` | `grid_combat.gd`, `grid_battle_live.gd`, `grid_story_integration.gd`, `grid_campaign.gd`, `capture_grid_battle.gd` |
| 전투 HUD | [체력·내기·기세·무공 선택](ui/battle-hud.md), [색상3안 검토](ui/battle-palette-candidates.md) | `scripts/battle_hud.gd`, `scripts/battle.gd` | `ui_states.gd`, `combat_updates.gd`, `battle_motion.gd`, `capture_battle_hud.gd` |
| 전투·아이콘 | [현재 규칙](systems/combat-actions-and-icons.md), [창법](systems/spear-balance.md) | `scripts/battle.gd`, `combat_actions.gd`, `data/icon_manifest.json` | `combat_updates.gd`, `spear_balance.gd` |
| 무림맹 중급 무공5종 | [설정·수치·전수 구분](martial-arts/alliance-intermediate.md) | `data/alliance_martial_arts.json`, `scripts/martial_arts.gd` | `alliance_arts.gd`, `combat_updates.gd` |
| 남궁세가·청애채 토벌 | [돌아올 터전·맵·협공·영약](quests/namgung-campaign.md) | `scripts/namgung_campaign.gd`, `data/namgung_campaign.json`, `special_elixirs.json` | `namgung_campaign.gd`, `trading.gd` |
| 0장 전투 튜토리얼 | [단계·조건·화면](systems/battle-lesson.md) | `scripts/battle_lesson.gd`, `grid_battle.gd` | `battle_lesson.gd`, `grid_story_integration.gd` |
| 무공·무기·내기 | [실제 구현 무공 목록](martial-arts/implemented-catalog.md), [최신 위력·비용·범위 재편](martial-arts/redesign-v2.md), [범위·효과 그림](martial-arts/range-diagrams/README.md), [기본공격](systems/basic-attack.md), [스탯 역할 확정](systems/stat-roles.md), [무공](martial-arts/basic-attacks.md), [7×5 재설계 검토](martial-arts/grid-basic-redesign.md), [기민 행동권 실험](reviews/grid-initiative-paak.md), [무기](systems/weapons.md), [내기](systems/inner-qi.md) | `data/basic_martial_arts.json`, `weapons.json`, `scripts/inner_qi.gd` | `martial_arts.gd`, `weapons.gd`, `weapon_requirements.gd`, `inner_qi.gd` |
| 산적 토벌 | [진행](story/chapter-01-bandit-campaign.md), [원고](story/chapter-01-bandit-dialogues.md) | `scripts/bandit_story.gd`, `data/changsha_bandit_story.json` | `bandit_story.gd` |
| 편의 8종·Q/F2/L | [입구·동작·검증](systems/adventure-usability.md) | `scripts/adventure_ui.gd`, `game_options.gd`, `item_comparison.gd`, `interaction_indicator.gd` | `adventure_features.gd` |
| 장착 무기 외형 | [검·도·창·맨손 실제 화면](systems/equipment-appearance.md) | `scripts/player.gd`, `scripts/carried_equipment.gd`, `scripts/battle.gd` | `equipment_visuals.gd`, `battle_motion.gd`, `capture_equipment_overview.gd` |
| 해상도·바닥 표시 | [720/1080/1440p·실제 캡처](ui/resolution-audit.md) | `scripts/terrain_rendering.gd`, `shaders/terrain_detail.gdshader` | `resolution_layout.gd`, `capture_resolution_audit.gd`, `map_art.gd`, `prologue_f_input.gd` |
| 보행·통로 | [거리 기반 사방 보행·문 점검](systems/walk-and-passages.md) | `scripts/player.gd` | `walk_passages.gd`, `road_stride.gd`, `movement_scale.gd`, `wuchang.gd`, `side_stride_render.gd` |
| 탐험 HUD | [목표·이름·표식·알림](ui/exploration-hud.md) | `scripts/exploration_hud.gd`, `minimap.gd`, `adventure_ui.gd` | `exploration_hud.gd`, `capture_exploration_hud.gd`, `quest_update.gd`, `compact_hud_gate.gd` |
| UI 상태 표시 | [선택·포커스·사용 불가](ui/interaction-states.md) | `scripts/ui.gd`, `paper_menu_base.gd` 및 각 메뉴 | `ui_states.gd`, `capture_ui_states.gd`, `paper_menu_live.gd`, `trading.gd`, `combat_updates.gd` |
| 타이틀 | [화면·이어하기·불러오기](ui/title-live.md) | `scripts/title_screen.gd`, `save_system.gd` | `title_screen.gd`, `capture_title.gd`, `saves.gd`, `death_flow.gd` |
| 저장·설정 | [규칙](systems/save-slots.md) | `scripts/save_system.gd`, `settings_menu.gd` | `save_restrictions.gd`, `saves.gd` |
| 시설 NPC 그림 재사용 | [직업별2종 목록](characters/service-npc-gallery.md), [제작 원칙](characters/creation-guidelines.md) | `data/service_npc_portraits.json`, `data/city_standards.json` | 원본 경로·기존 도시 배정 확인 |
| 기본 NPC 그림 재사용 | [제작 원칙](characters/creation-guidelines.md) | `data/basic_npc_portraits.json`, `scripts/dialogue_portraits.gd` | `basic_npc_portraits.gd`, `conversation_tools.gd` |
| 대화·미술·UI | [초상화](systems/dialogue-portraits.md), [기록·중복 방지](systems/layered-city-and-conversation.md), [UI](systems/wuxia-ui-style.md), [모션](systems/battle-motion.md) | `scripts/dialogue_portraits.gd`, `dialogue_history.gd`, `battle_actor.gd`, `data/portrait_framing.json` | `conversation_tools.gd`, `dialogue.gd`, `ink_ui.gd`, `battle_motion.gd` |
| 세계관·인물 | [세력](factions.md), [통합](factions-overview.md), [인물 제작 원칙](characters/creation-guidelines.md) | `docs/factions/`, `docs/characters/`, `assets/portraits/` | 관련 문서·이미지 확인 |

위 표의 `scripts/`, `data/`, `assets/maps/`는 `godot/` 아래다. 같은 셀에서 생략한 파일의 폴더는 앞 파일과 같다.

기타 자료: [이전 웹 데모](../demo/README.md), [인물 갤러리](REFERENCE_GALLERY.md), [저장소 사용법·정리 기록](REPOSITORY_GUIDE.md). `reviews/`의 제안·결과와 `archive/`의 과거 기록은 관련 작업에서만 읽는다.

남경 주민: [일반 주민20명 이름·설정](characters/nanjing-residents.md).

인물: [육소전 전용 초상화·탐험 도트](characters/lu-xiaozhuan.md).

남경 일반 의뢰: [비단 한 필의 값](quests/nanjing-silk.md).

남경 일반 의뢰2: [한 수레의 무게](quests/nanjing-cart.md).

검토: [서적 의뢰 보상 쇄랑도법·서적/아이콘 시안](martial-arts/swaerang-proposal.md) — 게임 미구현.

- [남경 일반 의뢰3 · 빌려준 책, 돌아오지 않는 사람 / 서적 사용 학습](quests/nanjing-book.md)

- [남경 일반 의뢰4 · 관의 이름을 빌린 자](quests/nanjing-levy.md)
- [남경 일반 의뢰5 · 끊어진 계선줄 (전투 구현)](quests/nanjing-waterfront.md)

- [I/K 한지 UI 실장 · 소지품/무공](ui/paper-menu-live.md)

- [한지 대화창 일괄 적용 · 도원 왼쪽/상대 오른쪽](ui/paper-dialogue-live.md)

- [모용세가 태호 장원·교류 의뢰](cities/murong-estate.md) · [실제 적용 대사](quests/murong-exchange.md)

- [소주 남쪽 · 강남 운하길](cities/suzhou-hangzhou-canal.md)

- [항주 · 서호와 취월루](cities/hangzhou.md)

- [탐험 캐릭터 전체23종·주인공 무기/방향 비교](characters/exploration-sprite-comparison.md)

항주 취월루: [실내 구성·F 출입·실제 화면](cities/cuiyue-hall.md). 단일 연회장과 독립 가구/충돌/Y정렬, 저장·지도·의뢰 출구 안내.

항주·취월루 주민: [16명 설정·대화·전용3인·배치 화면](characters/hangzhou-residents.md).

항주 일반 의뢰5종: [진행·보수·전체 대화·소길의 짝사랑](quests/hangzhou.md). `hangzhou_quests.gd`/`hangzhou_errand.gd`, 기존 주민16명 재사용.

취월루 후속 사건: [공개 장면·개방 조건·전투 배경안](quests/cuiyue-incident-proposal.md). 초기 기획 기록이며, 현재는 아래 구현 문서와 게임 데이터가 우선한다.

취월루 후속 사건 구현: [네 선행 조건·제압전·남경 접점 대화·보상·실제 화면](quests/cuiyue-incident.md). 이전 기획안보다 우선하며 `cuiyue_incident.gd`/`cuiyue_incident.json`이 현재 원본이다.
