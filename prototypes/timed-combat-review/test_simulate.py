"""Small mechanism checks: these do not establish balance or subjective fun."""
import unittest
from simulate import Combat, Fighter, Job, TIMING, DATA, ARTS, make_fighters, health, raw, damage, cost


class ClockChecks(unittest.TestCase):
    def fresh(self):
        hero, boss = make_fighters('cheongpung', 2)
        hero.qi = boss.qi = 100
        return Combat(hero, boss, record=True)

    def test_source_stats_and_shared_formulas(self):
        hero, boss = make_fighters('cheongpung')
        self.assertEqual((hero.hp, boss.hp), (374, 328))
        self.assertEqual(sum(hero.stats.values()), 104)
        self.assertEqual(cost('gwanpung', 'balanced_spear'), 27)
        self.assertEqual(damage(raw('danseok', boss.stats, boss.weapon), hero.stats, hero.weapon), 133)

    def test_build_is_affordable_without_prologue_treasure(self):
        rewards = DATA['changsha_quest_rewards']['quests'].values()
        self.assertEqual(sum(q['money'] for q in rewards), 1250)
        self.assertEqual(sum(q['stat_gains']['insight'] for q in rewards), 18)
        for art, definition in ARTS.items():
            if definition['grade'] != 'low': continue
            hero, _ = make_fighters(art)
            pill_ids = ['bear_strength_pill', 'light_step_pill', 'bone_fortifying_pill', 'qi_nourishing_pill']
            counts = [0, 0, 0, 6] if art == 'ungi' else [1, 1, 2, 2]
            stats = dict(strength=10, agility=10, constitution=10, inner=10, insight=28)
            for key, count in zip(pill_ids, counts):
                for stat, gain in DATA['low_grade_elixirs'][key]['permanent_stat_gains'].items():
                    stats[stat] += gain * count
            self.assertEqual(hero.stats, stats)
            spend = (0 if hero.weapon == 'none' else 300) + 350 + 600
            self.assertLessEqual(spend, 1250)

    def test_movement_arrival_and_recovery(self):
        sim = self.fresh()
        a = sim.fighters[0]
        sim.start(0, ('move', 1, (2, 3)))
        self.assertEqual(a.job.end, 10)
        sim.t = 7; sim.resolve_moves(); self.assertEqual(a.pos, (2, 2))
        sim.t = 8; sim.resolve_moves(); self.assertEqual(a.pos, (2, 3))
        sim.t = 9; sim.finish(); self.assertIsNotNone(a.job)
        sim.t = 10; sim.finish(); self.assertIsNone(a.job)
        self.assertEqual(a.qi, 120)

    def test_guard_boundaries(self):
        sim = self.fresh(); a = sim.fighters[0]
        a.job = Job('basic_defense', 0)
        for t, expected in ((1, 0), (2, 20), (7, 20), (8, 0), (9, 0)):
            sim.t = t; self.assertEqual(sim.guard(a), expected)

    def test_sword_guard_only_after_release(self):
        sim = self.fresh(); a = sim.fighters[0]
        a.job = Job('samjae', 0)
        for t, expected in ((4, 0), (5, 20), (11, 20), (12, 0)):
            sim.t = t; self.assertEqual(sim.guard(a), expected)

    def test_advance_then_strike_and_retreat_after_strike(self):
        sim = self.fresh(); a, b = sim.fighters
        a.pos, b.pos = (1, 2), (3, 2)
        a.job = Job('cheongpung', 0, 0)
        sim.t = 8; sim.resolve_moves(); self.assertEqual(a.pos, (2, 2))
        sim.resolve_hits(); self.assertLess(b.hp, health(b.stats))
        a.pos, b.pos = (2, 2), (3, 2)
        a.job = Job('yusu', 10, 0)
        sim.t = 15; sim.resolve_moves(); sim.resolve_hits()
        self.assertEqual(a.pos, (2, 2))
        sim.t = 18; sim.resolve_moves(); self.assertEqual(a.pos, (1, 2))

    def test_late_dodge_is_hit_early_dodge_escapes_heavy(self):
        sim = self.fresh(); a, b = sim.fighters
        sim.start(0, ('move', 1, (2, 3)))
        b.job = Job('basic_attack', 0, 2)
        sim.t = 3; sim.resolve_moves(); sim.resolve_hits()
        self.assertLess(a.hp, health(a.stats))
        sim = self.fresh(); a, b = sim.fighters
        sim.start(0, ('move', 1, (2, 3)))
        b.job = Job('danseok', 0, 2)
        sim.t = 8; sim.resolve_moves()
        sim.t = 9; sim.resolve_hits()
        self.assertEqual(a.hp, health(a.stats))

    def test_simultaneous_lethal_attacks_both_resolve(self):
        sim = self.fresh(); a, b = sim.fighters
        a.hp = b.hp = 1
        a.job, b.job = Job('basic_attack', 0, 0), Job('basic_attack', 0, 2)
        sim.t = 3; sim.resolve_hits()
        self.assertEqual((a.hp, b.hp), (0, 0))

    def test_no_overlapping_destinations(self):
        sim = self.fresh(); a, b = sim.fighters
        a.pos, b.pos = (1, 2), (3, 2)
        a.job, b.job = Job('move', 0, 0, (2, 2)), Job('move', 0, 2, (2, 2))
        sim.t = 8; sim.resolve_moves()
        self.assertEqual((a.pos, b.pos), ((1, 2), (3, 2)))

    def test_public_view_excludes_future_plan_and_qi(self):
        sim = self.fresh()
        sim.fighters[1].job = Job('danseok', 0, 2)
        view = sim.visible(0)
        self.assertEqual(set(view), {'position', 'phase', 'kind', 'pose', 'facing', 'elapsed'})
        self.assertEqual(view['pose'], 'line')

    def test_does_not_choose_guard_that_is_already_too_late(self):
        sim = self.fresh()
        sim.fighters[1].job = Job('danseok', 41, 2)
        sim.t = 49
        self.assertIsNone(sim.defense_choice(0, sim.attack_options(0)))

    def test_wait_never_recovers_qi(self):
        sim = self.fresh(); a = sim.fighters[0]
        sim.start(0, ('wait', 0, None)); sim.t = 2; sim.finish()
        self.assertEqual(a.qi, 100)

    def test_observer_waits_without_reading_new_enemy_input(self):
        hero, boss = make_fighters('cheongpung', 1)
        sim = Combat(hero, boss, policy='read_counter')
        self.assertEqual(sim.choose(0)[0], 'wait')
        self.assertIsNone(boss.job)

    def test_release_length_not_multihit(self):
        sim = self.fresh(); a, b = sim.fighters
        b.job = Job('hoepung', 0)
        for t in range(10, 15):
            sim.t = t; sim.resolve_hits()
        self.assertEqual(b.hit_count, 1)


if __name__ == '__main__': unittest.main()
