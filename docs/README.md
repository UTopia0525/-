# 작업별 색인

현재 상태는 [CLI 인계](CLI_HANDOFF.md), 실행은 [Godot 안내](../godot/README.md)를 참고한다. 아래 경로는 저장소 루트 기준이다. 문서와 관련 소스만 먼저 읽고 필요한 검사를 선택한다.

| 작업 | 설명 | 주요 코드·데이터 | 기존 검사 (`godot/tests/`) |
| --- | --- | --- | --- |
| 0장·분기 | [진행](story/chapter-00-implementation.md), [원고](story/chapter-00-dialogues.md) | `scripts/prologue.gd`, `data/prologue_dialogues.json` | `prologue.gd`, `chapter_one.gd` |
| 도입 의뢰3종 | [진행·보상](quests/trade-intro.md) | `scripts/trade_intro.gd`, `data/trade_intro.json` | `onboarding_menus.gd` |
| 일반 의뢰6종 | [실제 진행·표식](systems/adventure-usability.md), [목록](quests/changsha.md), [흐름](quests/quest-flow.md), [원고](quests/changsha-dialogues.md) | `data/normal_quests.json`, `scripts/ordinary_quests.gd`, `quest_navigation.gd` | `adventure_features.gd`, `quest_navigation.gd` |
| 무창 대련·조식수원공 | [진행·전수·제한](quests/wuchang-duel-proposal.md) | `scripts/duel_quest.gd`, `data/wuchang_duel_quest.json`, `data/support_martial_arts.json`, `scripts/combat_actions.gd` | `duel_quest.gd`, `josik_suwon.gd` |
| 무창 장인의 이름값 | [진행·원고·검증](quests/wuchang-artisan.md) | `scripts/artisan_quest.gd`, `data/wuchang_artisan_quest.json` | `artisan_quest.gd` |
| 무창 약초꾼 의뢰 | [진행·원고·난이도](quests/wuchang-herbalist.md) | `scripts/herbalist_quest.gd`, `data/wuchang_herbalist_quest.json` | `herbalist_quest.gd` |
| 도시 간 육로 | [산길·출입·지도·저장](cities/changsha-wuchang-road.md) | `scripts/overland_travel.gd`, `mountain_road_map.gd`, `assets/maps/changsha-wuchang/layout.json` | `overland_travel.gd`, `capture_overland.gd` |
| 무림맹 경비·총관·교관 | [인물](characters/alliance-headquarters.md), [출입·진행 구분](story/alliance-visit-foundation.md) | `data/alliance_characters.json`, `scripts/alliance_visit.gd` | `alliance_visit.gd`, `capture_alliance_visit.gd` |
| 무창 민간 주민 | [8인 설정·대사·그림](characters/wuchang-civilians.md) | `data/wuchang_residents.json`, `scripts/exploration.gd`, `dialogue_portraits.gd` | `wuchang_residents.gd`, `capture_wuchang_residents.gd` |
| 맵 미술 통일 | [산길·무창·총무당](cities/regional-map-art.md) | `scripts/*ground.gd`, `assets/maps/*/ground.png` | `map_art.gd`, `capture_map_art.gd` |
| 무창·무림맹 지도 | [배치·답사·범위](cities/wuchang.md), [조직 설정](factions/murim-alliance.md) | `scripts/wuchang_map.gd`, `wuchang_preview.gd`, `wuchang_ground.gd`, `assets/maps/wuchang/layout.json` | `wuchang.gd`, `capture_wuchang.gd` |
| 장사 주민 정리·이름 | [의뢰 관련11인 설정](characters/changsha-quest-residents.md) | `assets/maps/changsha/layout.json`, `scripts/ordinary_quests.gd`, `main.gd` | `changsha_residents.gd`, `quest_navigation.gd`, `adventure_features.gd` |
| 도시·충돌 | [인물 비율·이동](systems/exploration-scale.md), [도시 기준](cities/city-standards.md), [현재 장사·오브젝트](systems/layered-city-and-conversation.md) | `scripts/exploration.gd`, `city_scenery.gd`, `assets/maps/changsha/layout.json` | `layered_city.gd`, `city_collision.gd`, `changsha.gd`, `city_services.gd` |
| 거래·I/K·성장 | [거래](systems/city-trading.md), [정비창](systems/player-menus.md) | `scripts/player_progress.gd`, `city_service.gd`, `player_menu.gd` | `trading.gd`, `onboarding_menus.gd` |
| 전투·아이콘 | [현재 규칙](systems/combat-actions-and-icons.md), [창법](systems/spear-balance.md) | `scripts/battle.gd`, `combat_actions.gd`, `data/icon_manifest.json` | `combat_updates.gd`, `spear_balance.gd` |
| 무림맹 중급 무공5종 | [설정·수치·전수 구분](martial-arts/alliance-intermediate.md) | `data/alliance_martial_arts.json`, `scripts/martial_arts.gd` | `alliance_arts.gd`, `combat_updates.gd` |
| 무공·무기·내기 | [무공](martial-arts/basic-attacks.md), [무기](systems/weapons.md), [내기](systems/inner-qi.md) | `data/basic_martial_arts.json`, `weapons.json`, `scripts/inner_qi.gd` | `martial_arts.gd`, `weapons.gd`, `weapon_requirements.gd`, `inner_qi.gd` |
| 산적 토벌 | [진행](story/chapter-01-bandit-campaign.md), [원고](story/chapter-01-bandit-dialogues.md) | `scripts/bandit_story.gd`, `data/changsha_bandit_story.json` | `bandit_story.gd` |
| 편의 8종·Q/F2/L | [입구·동작·검증](systems/adventure-usability.md) | `scripts/adventure_ui.gd`, `game_options.gd`, `item_comparison.gd`, `interaction_indicator.gd` | `adventure_features.gd` |
| 저장·설정 | [규칙](systems/save-slots.md) | `scripts/save_system.gd`, `settings_menu.gd` | `save_restrictions.gd`, `saves.gd` |
| 시설 NPC 그림 재사용 | [직업별2종 목록](characters/service-npc-gallery.md), [제작 원칙](characters/creation-guidelines.md) | `data/service_npc_portraits.json`, `data/city_standards.json` | 원본 경로·기존 도시 배정 확인 |
| 기본 NPC 그림 재사용 | [제작 원칙](characters/creation-guidelines.md) | `data/basic_npc_portraits.json`, `scripts/dialogue_portraits.gd` | `basic_npc_portraits.gd`, `conversation_tools.gd` |
| 대화·미술·UI | [초상화](systems/dialogue-portraits.md), [기록·중복 방지](systems/layered-city-and-conversation.md), [UI](systems/wuxia-ui-style.md), [모션](systems/battle-motion.md) | `scripts/dialogue_portraits.gd`, `dialogue_history.gd`, `battle_actor.gd`, `data/portrait_framing.json` | `conversation_tools.gd`, `dialogue.gd`, `ink_ui.gd`, `battle_motion.gd` |
| 세계관·인물 | [세력](factions.md), [통합](factions-overview.md), [인물 제작 원칙](characters/creation-guidelines.md) | `docs/factions/`, `docs/characters/`, `assets/portraits/` | 관련 문서·이미지 확인 |

위 표의 `scripts/`, `data/`, `assets/maps/`는 `godot/` 아래다. 같은 셀에서 생략한 파일의 폴더는 앞 파일과 같다.

기타 자료: [이전 웹 데모](../demo/README.md), [인물 갤러리](REFERENCE_GALLERY.md), [저장소 사용법·정리 기록](REPOSITORY_GUIDE.md). `reviews/`의 제안·결과와 `archive/`의 과거 기록은 관련 작업에서만 읽는다.
