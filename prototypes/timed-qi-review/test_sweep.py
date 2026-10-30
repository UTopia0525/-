import copy
import unittest
import sweep
from sweep import base, Budget, EnergyCombat, max_chain


class QiBudgetChecks(unittest.TestCase):
    def sim(self, cap=70):
        return EnergyCombat(*base.make_fighters('cheongpung'),budget=Budget('test',cap,table='B'),record=True)

    def test_cost_then_full_recovery_timing(self):
        s=self.sim();a=s.fighters[0];a.qi=70
        s.start(0,('samjae',0,None))
        self.assertEqual(a.qi,35)
        s.t=5;s.finish();self.assertEqual(a.qi,35)
        s.t=11;s.finish();self.assertEqual(a.qi,35)
        s.t=12;s.finish();self.assertEqual(a.qi,55)

    def test_move_recovery_still_at_ten_not_eight(self):
        s=self.sim();a=s.fighters[0]
        s.start(0,('move',1,(1,3)))
        s.t=8;s.resolve_moves();s.finish();self.assertEqual(a.qi,20)
        s.t=10;s.finish();self.assertEqual(a.qi,40)

    def test_cap_and_wait(self):
        s=self.sim();a=s.fighters[0];a.qi=65
        s.start(0,('basic_defense',0,None));s.t=10;s.finish()
        self.assertEqual(a.qi,70);self.assertEqual(s.cap_waste[0],15)
        s.start(0,('wait',0,None));s.t=12;s.finish();self.assertEqual(a.qi,70)

    def test_cannot_spend_above_available_qi(self):
        s=self.sim();a=s.fighters[0];a.qi=34
        self.assertFalse(any(o[0]=='samjae' for o in s.attack_options(0)))
        with self.assertRaises(AssertionError):s.start(0,('samjae',0,None))

    def test_discounts_round_after_new_cost(self):
        b=Budget('test',70,table='B')
        self.assertEqual(b.cost('gwanpung','balanced_spear'),59)
        self.assertEqual(b.cost('yeonhwan','balanced_spear'),68)
        self.assertEqual(Budget('test',100,3).cost('gwanpung','balanced_spear'),81)

    def test_analytical_chain_matches_bruteforce(self):
        for cap in (40,65,70,80,120,500):
            for price in (20,35,50,59,68,120):
                for recovery in (12,20,28):
                    qi=cap;n=0
                    while qi>=price and n<1000:
                        qi=min(cap,qi-price+recovery);n+=1
                    expected='unlimited' if n==1000 else n
                    self.assertEqual(max_chain(cap,price,recovery),expected)

    def test_legacy_budget_preserves_original_results(self):
        for art in sweep.ART_IDS:
            hero,boss=base.make_fighters(art)
            old=base.Combat(copy.deepcopy(hero),copy.deepcopy(boss),policy='efficient',reaction=3,seed=1)
            new=EnergyCombat(hero,boss,budget=Budget('baseline',500),refill_policy='legacy',reaction=3,seed=1)
            first,second=old.run(),new.run()
            self.assertEqual(first,{k:second[k] for k in first})

    def test_d_cap_eighty_blocks_back_to_back_heavy(self):
        for art in ('danseok','gwanpung','cheolsan','ungi'):
            s=EnergyCombat(*base.make_fighters(art),budget=Budget('D',80,table='D'))
            a=s.fighters[0];a.qi=80
            s.start(0,(art,0,None));s.t=a.job.end;s.finish()
            self.assertLess(a.qi,s.budget.cost(art,a.weapon))

    def test_palm_chain_threshold_eighty_two(self):
        for cap,can_repeat in ((80,False),(81,False),(82,True),(85,True)):
            s=EnergyCombat(*base.make_fighters('ungi'),budget=Budget('D',cap,table='D'))
            a=s.fighters[0];a.qi=cap
            s.start(0,('ungi',0,None));s.t=a.job.end;s.finish()
            self.assertEqual(a.qi>=55,can_repeat)

    def test_symmetric_chase_yield_uses_only_own_history(self):
        s=self.sim();s.t=100
        for i in (0,1):
            s.history[i]=[dict(art='move',origin=p) for p in ((0,2),(1,2),(0,2),(1,2))]
        # Force the local decision coin for the fixture, without reading the other new command.
        for rng in s.rngs:rng.random=lambda:0
        self.assertEqual(s.choose(0)[0],'wait')
        self.assertEqual(s.choose(1)[0],'wait')
        self.assertEqual(s.yield_until,[110,110])


if __name__=='__main__':unittest.main()
