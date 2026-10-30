import unittest
import catalogue as cat
import engine as eng
import benchmark as bench


class ProgressionChecks(unittest.TestCase):
    def setUp(self):eng.install('graded')
    def pair(self,art='josik_suwon',inner=20):
        stats=bench.profile(inner)
        hero=eng.base.Fighter('도원',stats,'none',['basic_attack','basic_defense',art],(2,2))
        enemy=eng.base.Fighter('검사',bench.profile(inner),'refined_sword',['basic_attack'],(3,2))
        return eng.Combat(hero,enemy,record=True)

    def test_cap_formula_does_not_flatten_at_eighty(self):
        formula=cat.FORMULAS['floor80_40_2I']
        self.assertEqual([formula(i) for i in (10,20,50,100,150,200)],[80,80,140,240,340,440])

    def test_existing_middle_catalogue_complete(self):
        mids={k for k,d in cat.ORIGINAL.items() if d['grade']=='intermediate'}
        self.assertEqual(mids,{'hoeryu','paak','gwanak','banseok','jungun','swaerang','josik_suwon'})
        for key in mids:self.assertIn(key,cat.TIMINGS);self.assertIn(key,cat.COSTS)

    def test_middle_can_be_funded_at_inner_ten(self):
        b=eng.Budget()
        for style,arts in cat.STYLE_ARTS.items():
            self.assertLessEqual(b.cost(arts['mid'],bench.weapon(style,1)),b.capacity(10))

    def test_upper_all_payable_at_inner_two_hundred(self):
        b=eng.Budget()
        for key,d in cat.UPPER.items():
            style=d['weapon_style'];self.assertLessEqual(b.cost(key,bench.weapon(style,1)),b.capacity(200))

    def test_support_recovers_extra_plus_normal_at_finish_only(self):
        sim=self.pair();a=sim.fighters[0];a.qi=0
        sim.start(0,('josik_suwon',0,None))
        for t in (4,14,17):sim.t=t;sim.finish();self.assertEqual(a.qi,0)
        sim.t=18;sim.finish();self.assertEqual(a.qi,60)

    def test_support_requires_three_other_completed_actions(self):
        sim=self.pair();sim.start(0,('josik_suwon',0,None));sim.t=18;sim.finish()
        for count in range(3):
            self.assertLess(sim.completed[0],sim.support_ready[0])
            sim.start(0,('basic_defense',0,None));sim.t+=10;sim.finish()
        self.assertEqual(sim.completed[0],sim.support_ready[0])
        sim.start(0,('josik_suwon',0,None))

    def test_support_guard_is_not_lost_during_hit_resolution(self):
        sim=self.pair();a,b=sim.fighters
        a.job=eng.Job('josik_suwon',0)
        b.job=eng.Job('basic_attack',3,2)
        expected=eng.base.damage(eng.base.raw('basic_attack',b.stats,b.weapon),a.stats,a.weapon,20)
        before=a.hp;sim.t=6;sim.resolve_hits()
        self.assertEqual(before-a.hp,expected);self.assertEqual(sim.guard(a),20)

    def test_advance_attack_uses_new_job_timing(self):
        sim=self.pair('geumgang');a,b=sim.fighters
        a.pos,b.pos=(1,2),(3,2);a.qi=440;a.stats['inner']=200
        # Separate actor capacity for this fixture, without modifying the formula.
        sim.capacities[0]=440
        sim.start(0,('geumgang',0,None));sim.t=10;sim.resolve_moves();sim.resolve_hits()
        self.assertEqual(a.pos,(2,2));self.assertLess(b.hp,eng.base.health(b.stats))

    def test_scope_isolated_from_previous_review_catalogue(self):
        import simulate
        self.assertNotIn('yuha',simulate.ARTS)
        self.assertNotIn('josik_suwon',simulate.TIMING)

    def test_ranges_keep_three_cell_limit_including_displacement(self):
        for d in eng.CURRENT.values():
            for x,y in d['attack_offsets']:
                self.assertLessEqual(abs(x+d['advance'])+abs(y),3)
                if d['push']:self.assertLessEqual(abs(x+d['advance']+d['push'])+abs(y),3)

    def test_inner_specialist_profiles_do_not_receive_free_stats(self):
        for level in bench.LEVELS:
            for kind in ('balanced','inner','strength'):
                stats=bench.profile(level,kind);self.assertEqual(sum(stats.values()),5*level)
                self.assertTrue(all(0<=v<=200 for v in stats.values()))

    def test_resource_cycle_uses_actual_capacity_clipping(self):
        cycle=bench.resource_cycle(80,55,28,30)
        self.assertEqual(cycle['free_per_cast'],1)
        self.assertEqual(cycle['time_per_cast'],40)

    def test_capacity_and_recovery_support_growth_through_two_hundred(self):
        b=eng.Budget()
        values=[b.capacity(i) for i in range(201)]
        self.assertEqual(values,sorted(values))
        self.assertTrue(all(b.capacity(i)>i for i in range(201)))
        self.assertGreater(b.capacity(200),b.capacity(100))

    def test_support_can_be_worth_using_despite_capacity_waste(self):
        sim=self.pair('geumgang',150);a=sim.fighters[0]
        a.arts=['basic_attack','basic_defense','geumgang','josik_suwon']
        self.assertEqual(sim.support_choice(0)[0],'josik_suwon')


if __name__=='__main__':unittest.main()
