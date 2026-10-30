import copy
import unittest
import experiment as e
from cost_probe import AffordableBudget


class MixedActionChecks(unittest.TestCase):
    def sim(self,mask='full',minimum=100):
        return e.Combat(*e.pair(20,'heavy',1),mask=mask,budget=e.Budget(minimum=minimum),record=True)

    def test_round_minimum_changes_early_stage_only(self):
        self.assertEqual([e.Budget(minimum=50).capacity(i) for i in (10,20,30,50,200)],[60,80,100,140,440])
        self.assertEqual([e.Budget(minimum=100).capacity(i) for i in (10,20,30,50,200)],[100,100,100,140,440])
        self.assertEqual(e.Budget(minimum=50,offset=0).capacity(20),50)

    def test_affordable_cap_control_preserves_all_low_art_choices(self):
        for art,style in (('cheongpung','sword'),('yusu','sword'),('danseok','saber'),('hoepung','saber'),
                          ('gwanpung','spear'),('yeonhwan','spear'),('cheolsan','fist'),('ungi','palm')):
            self.assertLessEqual(AffordableBudget(minimum=50,offset=0).cost(art,e.previous.weapon(style,1)),50)

    def test_same_four_slots_and_no_fifth_art(self):
        for level in e.LEVELS:
            s=e.Combat(*e.pair(level,'duelist',0))
            self.assertEqual(len(s.fighters[0].arts),4)

    def test_removing_guard_does_not_remove_sword_passive(self):
        s=self.sim('no_guard');self.assertNotIn('basic_defense',s.fighters[0].arts)
        s.fighters[0].job=e.eng.Job('yusu',0)
        s.t=5;self.assertEqual(s.guard(s.fighters[0]),20)

    def test_sword_passive_is_not_counted_as_active_basic_guard(self):
        s=self.sim();a,b=s.fighters
        a.pos=(3,2);b.pos=(4,2)
        a.job=e.eng.Job('yusu',0,0,None,a.pos)
        b.job=e.eng.Job('basic_attack',2,2,None,b.pos)
        s.t=5;s.resolve_hits()
        self.assertGreater(a.guard_saved,0)
        self.assertEqual(s.active_guard_saved,0)

    def test_no_reposition_keeps_approach_but_not_retreat(self):
        s=self.sim('no_reposition')
        # Unaffordable advance arts must not prevent basic-attack approach.
        self.assertGreater(s.approach_distance(s.fighters[0].pos),0)
        self.assertTrue(s.moves())
        s.fighters[0].pos=(3,2)
        self.assertEqual(s.approach_distance(s.fighters[0].pos),0)
        self.assertEqual(s.moves(),[])
        s.fighters[0].pos=(0,2);s.fighters[1].pos=(5,2)
        self.assertTrue(s.moves())

    def test_counterfactual_does_not_mutate_live_fighters_or_rng(self):
        s=self.sim();before=copy.deepcopy(s.fighters);rng=[r.getstate() for r in s.rngs];history=copy.deepcopy(s.history)
        s.evaluate(s.candidates()[0])
        self.assertEqual(s.fighters,before);self.assertEqual(s.history,history)
        self.assertEqual([r.getstate() for r in s.rngs],rng)

    def test_score_has_no_diversity_or_repetition_reward(self):
        a=self.sim();b=self.sim()
        b.tactical_moves=100;b.active_guard_saved=10000;b.hit_by_art.update({'cheongpung':20,'yusu':20})
        option=a.candidates()[0]
        self.assertAlmostEqual(a.evaluate(option),b.evaluate(option))

    def test_only_a_really_disables_b(self):
        s=self.sim('only_A')
        self.assertIn('cheongpung',s.fighters[0].arts);self.assertNotIn('yusu',s.fighters[0].arts)

    def test_practical_merit_does_not_count_losing_longer(self):
        a=dict(winner='boss',hp=0,time=200,max_hp=380)
        b=dict(winner='boss',hp=0,time=100,max_hp=380)
        self.assertFalse(e.practical_better(a,b))


if __name__=='__main__':unittest.main()
