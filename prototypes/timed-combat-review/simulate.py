#!/usr/bin/env python3
"""Review-only simultaneous integer-clock combat. Does not import/run/edit Godot.

Uses live catalog power/ranges, proposed timings, deliberately simple observable-state
policies. These are deterministic scenario counts, not estimates of human win rates.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import random
import statistics
from collections import Counter, deque
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
FILES = ["basic_martial_arts", "martial_tactics", "weapons", "changsha_bandit_story", "changsha_quest_rewards", "low_grade_elixirs"]
DATA = {name: json.loads((ROOT / "godot/data" / (name + ".json")).read_text()) for name in FILES}
ARTS = DATA["basic_martial_arts"]
TACTICS = DATA["martial_tactics"]["entries"]
WEAPONS = DATA["weapons"]
BOSS = next(e for e in DATA["changsha_bandit_story"]["encounters"] if e["id"] == "bandit_ringleader")
TIMING = {
    "move": (3, 5, 2), "basic_defense": (2, 6, 2),
    "basic_attack": (3, 2, 5), "samjae": (5, 2, 5),
    "cheongpung": (6, 4, 5), "yusu": (5, 3, 8),
    "danseok": (9, 3, 9), "hoepung": (10, 5, 10),
    "gwanpung": (7, 2, 8), "yeonhwan": (9, 5, 8),
    "cheolsan": (6, 3, 8), "ungi": (8, 4, 8),
}
LABELS = {key: value["name"] for key, value in ARTS.items()} | {
    "move": "이동", "basic_attack": "기본공격", "basic_defense": "기본방어", "wait": "대기"}
DIRS = ((1, 0), (0, 1), (-1, 0), (0, -1))
STARTS = [((1, 2), (5, 2)), ((2, 2), (4, 2)), ((2, 2), (3, 2)),
          ((1, 1), (5, 3)), ((0, 0), (4, 1)), ((3, 4), (3, 0))]


def add(a, b): return a[0] + b[0], a[1] + b[1]
def manhattan(a, b): return abs(a[0] - b[0]) + abs(a[1] - b[1])
def rotate(offset, direction):
    f = DIRS[direction]
    return offset[0] * f[0] - offset[1] * f[1], offset[0] * f[1] + offset[1] * f[0]
def inside(p): return 0 <= p[0] < 7 and 0 <= p[1] < 5
def health(stats): return 220 + 3 * stats["strength"] + 5 * stats["constitution"]
def raw(art, stats, weapon):
    if art == "basic_attack": return stats["strength"] + stats["inner"]
    definition = ARTS[art]
    result = definition.get("base_damage", 0) + sum(stats[k] * v for k, v in definition["damage_coefficients"].items())
    if definition["required_weapon_type"] == WEAPONS.get(weapon, {}).get("weapon_type"):
        result *= 1 + WEAPONS.get(weapon, {}).get("attack_bonus_percent", 0) / 100
    return result
def cost(art, weapon):
    if art in ("move", "basic_attack", "basic_defense"): return 0
    definition = ARTS[art]
    reduction = WEAPONS.get(weapon, {}).get("qi_reduction_percent", 0) if definition["required_weapon_type"] == WEAPONS.get(weapon, {}).get("weapon_type") else 0
    return math.ceil(definition["qi_cost"] * (1 - reduction / 100))
def damage(power, stats, weapon, guard=0):
    g = stats["constitution"]
    passive = WEAPONS.get(weapon, {}).get("damage_reduction_percent", 0)
    return math.floor(max(0, power - g) * 100 / (100 + g) * (1 - passive / 100) * (1 - guard / 100) + 1e-8)
def offsets(art): return TACTICS[art]["attack_offsets"]


@dataclass
class Job:
    art: str
    start: int
    direction: int = 0
    destination: tuple | None = None
    origin: tuple = (0, 0)

    @property
    def impact(self):
        return self.start + TIMING[self.art][0] + (2 if self.art == "cheongpung" else 0)

    @property
    def end(self): return self.start + sum(TIMING[self.art])


@dataclass
class Fighter:
    name: str
    stats: dict
    weapon: str
    arts: list
    pos: tuple
    hp: int = 0
    qi: int = 0
    job: Job | None = None
    next_decision: int = 0
    previous: str = ""
    last_move: int = -100
    actions: list = field(default_factory=list)
    hit_count: int = 0
    misses: int = 0
    damage_taken: int = 0
    guard_saved: int = 0
    qi_recovered: int = 0
    move_qi_recovered: int = 0
    blocked_step: tuple | None = None

    def __post_init__(self):
        self.hp = health(self.stats)
        self.qi = self.stats["inner"]


class Combat:
    def __init__(self, hero, boss, policy="reactive", enemy_style="pressure", reaction=0, seed=0, record=False, qi_mode="action", guard_enabled=True):
        self.fighters = [hero, boss]
        self.policy, self.enemy_style, self.reaction = policy, enemy_style, reaction
        self.rngs = [random.Random(seed * 2), random.Random(seed * 2 + 1)]
        self.t = 0
        self.record = record
        self.log = []
        self.frames = []
        self.qi_mode = qi_mode
        self.guard_enabled = guard_enabled
        self.boss_initial_hp = boss.hp

    def log_event(self, kind, **fields):
        if self.record: self.log.append(dict(t=self.t, kind=kind, **fields))

    def phase(self, a):
        if not a.job: return "ready"
        j = a.job
        prep, active, _ = TIMING[j.art]
        age = self.t - j.start
        return "prepare" if age < prep else "release" if age < prep + active else "recover"

    def visible(self, observer):
        """No exact art ID, damage, impact/end time, qi, future destination or command."""
        a = self.fighters[1 - observer]
        phase = self.phase(a)
        kind, pose, age = "idle", "none", 0
        if a.job:
            art = a.job.art
            age = self.t - a.job.start
            if art == "move": kind = "move"
            elif art == "basic_defense": kind = "guard"
            else:
                kind = "attack"
                pose = "quick" if art == "basic_attack" else "wide" if art == "hoepung" else "spread" if art in ("yeonhwan", "ungi", "cheongpung", "yusu") else "line"
                if observer == 0 and age < self.reaction:
                    kind, pose, phase = "idle", "none", "unknown"
        return {"position": a.pos, "phase": phase, "kind": kind, "pose": pose,
                "facing": a.job.direction if a.job else 0, "elapsed": age}

    def known_threat(self, observer, p=None):
        v = self.visible(observer)
        if v["kind"] != "attack" or v["phase"] != "prepare": return False
        p = self.fighters[observer].pos if p is None else p
        origin = v["position"]
        if v["pose"] == "wide":
            return p != origin and max(abs(p[0] - origin[0]), abs(p[1] - origin[1])) <= 1
        if v["pose"] == "spread":
            generic = [(1, -1), (1, 0), (1, 1), (2, -1), (2, 0), (2, 1)]
        elif v["pose"] == "quick":
            generic = [(1, 0)]
        else:
            generic = [(1, 0), (2, 0)]
        return p in [add(origin, rotate(o, v["facing"])) for o in generic]

    def can_step(self, index, p):
        return inside(p) and p != self.fighters[1 - index].pos

    def targets(self, index, art, direction, origin=None):
        a = self.fighters[index]
        p = a.pos if origin is None else origin
        return {add(p, rotate(o, direction)) for o in offsets(art)}

    def attack_options(self, index):
        a, b = self.fighters[index], self.fighters[1 - index]
        choices = []
        for art in a.arts:
            if art == "basic_defense" or a.qi < cost(art, a.weapon): continue
            for direction in range(4):
                origin = a.pos
                if TACTICS[art].get("advance", 0):
                    origin = add(origin, DIRS[direction])
                    if not self.can_step(index, origin): continue
                if b.pos in self.targets(index, art, direction, origin):
                    choices.append((art, direction, None))
        return choices

    def attack_score(self, index, option, punish=False):
        a = self.fighters[index]
        art = option[0]
        return raw(art, a.stats, a.weapon) / (sum(TIMING[art]) ** (0.65 if punish else 1))

    def ideal_distance(self, index, p, preferred=None):
        """BFS to a square from which the chosen martial art can currently hit."""
        a, b = self.fighters[index], self.fighters[1 - index]
        preferred = preferred or next((art for art in a.arts if art not in ("samjae", "basic_attack", "basic_defense")), "basic_attack")
        queue, seen = deque([(p, 0)]), {p}
        while queue:
            cell, distance = queue.popleft()
            for d in range(4):
                origin = add(cell, DIRS[d]) if TACTICS[preferred].get("advance", 0) else cell
                if not inside(origin) or origin == b.pos: continue
                if b.pos in self.targets(index, preferred, d, origin): return distance
            for delta in DIRS:
                nxt = add(cell, delta)
                if inside(nxt) and nxt != b.pos and nxt not in seen:
                    queue.append((nxt, distance + 1)); seen.add(nxt)
        return 99

    def approach(self, index, preferred=None):
        a = self.fighters[index]
        legal = [("move", d, add(a.pos, delta)) for d, delta in enumerate(DIRS) if self.can_step(index, add(a.pos, delta))]
        if not legal: return ("wait", 0, None)
        alternatives = [c for c in legal if c[2] != a.blocked_step]
        if alternatives: legal = alternatives
        scores = [self.ideal_distance(index, c[2], preferred) for c in legal]
        best = min(scores)
        return self.rngs[index].choice([c for c, score in zip(legal, scores) if score == best])

    def defense_choice(self, index, options):
        if not self.known_threat(index): return None
        a = self.fighters[index]
        v = self.visible(index)
        # Learned, coarse pose estimates, not the opponent job's exact impact/end.
        estimated_remaining = {"quick": 3, "line": 9, "wide": 10, "spread": 6}.get(v["pose"], 6) - v["elapsed"]
        if estimated_remaining >= 8:
            # Retreating sword can attack and exit a visible early windup together.
            for option in options:
                if option[0] == "yusu":
                    dest = add(a.pos, rotate((-1, 0), option[1]))
                    if self.can_step(index, dest) and not self.known_threat(index, dest): return option
            legal = [("move", d, add(a.pos, delta)) for d, delta in enumerate(DIRS)
                     if self.can_step(index, add(a.pos, delta)) and not self.known_threat(index, add(a.pos, delta))]
            if legal:
                best = min(self.ideal_distance(index, c[2]) for c in legal)
                return self.rngs[index].choice([c for c in legal if self.ideal_distance(index, c[2]) == best])
            return ("wait", 0, None)
        if 2 <= estimated_remaining < 8 and self.guard_enabled and "basic_defense" in a.arts:
            return ("basic_defense", 0, None)
        return None

    def choose(self, index):
        a = self.fighters[index]
        options = self.attack_options(index)
        observed = self.visible(index)
        if index == 0:
            policy = self.policy
            if policy == "read_counter" and observed["kind"] == "idle" and manhattan(a.pos, observed["position"]) <= 3:
                return ("wait", 0, None)
            if policy in ("reactive", "read_counter"):
                defensive = self.defense_choice(index, options)
                if defensive: return defensive
            if policy == "basic_only":
                basics = [o for o in options if o[0] == "basic_attack"]
                if basics: return basics[0]
            elif policy == "main_spam":
                main = next(art for art in a.arts if art not in ("basic_attack", "basic_defense", "samjae"))
                selected = [o for o in options if o[0] == main]
                if selected: return selected[0]
                basics = [o for o in options if o[0] == "basic_attack"]
                if basics: return basics[0]
            elif options:
                punish = policy in ("reactive", "read_counter") and observed["phase"] == "recover"
                return max(options, key=lambda o: self.attack_score(index, o, punish))
        else:
            if self.enemy_style == "cautious":
                defensive = self.defense_choice(index, options)
                if defensive: return defensive
            if options:
                if self.enemy_style == "erratic":
                    # Seeded uncertainty; no player command or future position inspection.
                    return self.rngs[index].choices(options, weights=[self.attack_score(index, o) for o in options])[0]
                if self.enemy_style == "pressure" and self.t - self.fighters[0].last_move < 13:
                    broad = [o for o in options if o[0] == "hoepung"]
                    if broad: return broad[0]
                return max(options, key=lambda o: self.attack_score(index, o))
        return self.approach(index, "basic_attack" if index == 0 and self.policy == "basic_only" else None)

    def start(self, index, option):
        a = self.fighters[index]
        art, direction, destination = option
        assert a.job is None and self.t >= a.next_decision
        if art == "wait":
            a.next_decision = self.t + 2
        else:
            assert a.qi >= cost(art, a.weapon)
            if art == "move": assert self.can_step(index, destination) and manhattan(a.pos, destination) == 1
            else: assert art in a.arts
            a.qi -= cost(art, a.weapon)
            a.job = Job(art, self.t, direction, destination, a.pos)
            if art == "move": a.last_move = self.t
        a.actions.append(art)
        a.previous = art
        self.log_event("start", actor=index, art=art, direction=direction, destination=destination,
                       impact=a.job.impact if a.job and art not in ("move", "basic_defense") else None,
                       end=a.job.end if a.job else a.next_decision)

    def guard(self, a):
        if not a.job: return 0
        j = a.job
        if j.art == "basic_defense" and j.start + 2 <= self.t < j.start + 8: return 20
        if j.art in ARTS and ARTS[j.art]["weapon_style"] == "sword" and j.impact <= self.t < j.end: return 20
        return 0

    def resolve_moves(self):
        destinations = {}
        for i, a in enumerate(self.fighters):
            j = a.job
            if not j: continue
            prep, active, _ = TIMING[j.art]
            if j.art == "move" and self.t == j.start + prep + active: destinations[i] = j.destination
            elif j.art == "cheongpung" and self.t == j.start + prep + 2: destinations[i] = add(a.pos, DIRS[j.direction])
            elif j.art == "yusu" and self.t == j.start + prep + active: destinations[i] = add(a.pos, rotate((-1, 0), j.direction))
        valid = {i: p for i, p in destinations.items() if self.can_step(i, p)}
        if len(valid) == 2 and valid[0] == valid[1]: valid = {}
        for i, p in destinations.items():
            self.fighters[i].blocked_step = None if i in valid else p
            if i not in valid: self.log_event("blocked", actor=i, destination=p)
        for i, p in valid.items():
            self.fighters[i].pos = p
            self.log_event("move", actor=i, destination=p)
        assert self.fighters[0].pos != self.fighters[1].pos

    def resolve_hits(self):
        hits = []
        for i, a in enumerate(self.fighters):
            j = a.job
            if not j or j.art in ("move", "basic_defense") or self.t != j.impact: continue
            b = self.fighters[1 - i]
            if b.pos not in self.targets(i, j.art, j.direction):
                a.misses += 1
                self.log_event("miss", actor=i, art=j.art)
                continue
            power = raw(j.art, a.stats, a.weapon)
            amount = damage(power, b.stats, b.weapon, self.guard(b))
            saved = damage(power, b.stats, b.weapon, 0) - amount
            hits.append((i, amount, saved))
        # Both attacks committed at a timestamp resolve, including mutual kills.
        for i, amount, saved in hits:
            a, b = self.fighters[i], self.fighters[1 - i]
            b.hp = max(0, b.hp - amount)
            b.damage_taken += amount
            b.guard_saved += saved
            a.hit_count += 1
            self.log_event("hit", actor=i, art=a.job.art, damage=amount, guard_saved=saved, target_hp=b.hp)
        pushes = {}
        for i, _, _ in hits:
            a, b = self.fighters[i], self.fighters[1 - i]
            if a.hp <= 0 or b.hp <= 0 or not TACTICS[a.job.art].get("push", 0): continue
            p = add(b.pos, DIRS[a.job.direction])
            if self.can_step(1 - i, p): pushes[1 - i] = p
        if len(pushes) == 2 and pushes[0] == pushes[1]: pushes = {}
        for i, p in pushes.items():
            self.fighters[i].pos = p
            self.log_event("push", actor=i, destination=p)

    def finish(self):
        for i, a in enumerate(self.fighters):
            if a.job and self.t == a.job.end:
                gain = a.stats["inner"] if self.qi_mode == "action" else 0
                before = a.qi
                a.qi = min(500, a.qi + gain)
                a.qi_recovered += a.qi - before
                if a.job.art == "move": a.move_qi_recovered += a.qi - before
                self.log_event("finish", actor=i, art=a.job.art, qi=a.qi, hp=a.hp)
                a.job = None

    def frame(self):
        if self.record:
            self.frames.append({"t": self.t, "actors": [{"pos": a.pos, "hp": a.hp, "qi": a.qi,
                "art": a.job.art if a.job else "wait", "phase": self.phase(a),
                "end": a.job.end if a.job else self.t, "facing": a.job.direction if a.job else 0}
                for a in self.fighters]})

    def run(self, limit=800):
        for t in range(limit + 1):
            self.t = t
            if self.qi_mode == "clock" and t > 0 and t % 10 == 0:
                for a in self.fighters:
                    before = a.qi; a.qi = min(500, a.qi + a.stats["inner"]); a.qi_recovered += a.qi - before
            self.resolve_moves()
            self.resolve_hits()
            if any(a.hp <= 0 for a in self.fighters):
                self.frame()
                break
            self.finish()
            # Both choose against the same pre-command state; neither reads the other's new command.
            commands = [(i, self.choose(i)) for i, a in enumerate(self.fighters) if a.job is None and t >= a.next_decision]
            for i, command in commands: self.start(i, command)
            self.frame()
        a, b = self.fighters
        attacks = [art for art in a.actions if art not in ("move", "basic_defense", "wait")]
        counts = Counter(attacks)
        streak = longest = 0
        last = None
        for art in attacks:
            streak = streak + 1 if art == last else 1
            longest = max(longest, streak); last = art
        return {"winner": "draw" if a.hp <= 0 and b.hp <= 0 else "hero" if b.hp <= 0 else "boss" if a.hp <= 0 else "timeout",
            "time": self.t, "hero_hp": a.hp, "boss_hp": b.hp,
            "hero_max_hp": health(a.stats), "hero_qi": a.qi,
            "hero_stats": a.stats, "hero_weapon": a.weapon, "hero_arts": a.arts,
            "boss_initial_hp": self.boss_initial_hp,
            "actions": dict(Counter(a.actions)), "enemy_actions": dict(Counter(b.actions)),
            "attack_share": max(counts.values()) / len(attacks) if attacks else 0,
            "unique_attacks": len(counts), "longest_attack_streak": longest,
            "hero_hits": a.hit_count, "hero_misses": a.misses, "boss_misses": b.misses,
            "guard_saved": a.guard_saved, "move_qi_recovered": a.move_qi_recovered,
            "damage_taken": a.damage_taken}


def make_fighters(art, start=0, dual=False):
    # Six legal pills, all nine Changsha errands: 1,250 mun + insight18.
    # 1 bear + 1 light + 2 bone + 2 qi -> 18/18/20/20/28.
    stats = dict(strength=18, agility=18, constitution=20, inner=20, insight=28)
    if art == "ungi":
        # Six qi pills to actually satisfy inner26; same pill spend, 300 mun left over.
        stats = dict(strength=16, agility=16, constitution=16, inner=28, insight=28)
    weapon_type = ARTS[art]["required_weapon_type"]
    weapon = {"sword": "refined_sword", "saber": "thickback_saber", "spear": "balanced_spear", "none": "none"}[weapon_type]
    arts = ["basic_attack", "basic_defense", art]
    if dual:
        counterpart = {"cheongpung": "yusu", "danseok": "hoepung", "gwanpung": "yeonhwan", "cheolsan": "ungi"}[art]
        arts.append(counterpart)
        if art == "cheolsan": stats = dict(strength=16, agility=16, constitution=16, inner=28, insight=28)
    elif weapon_type == "sword": arts.insert(2, "samjae")
    for skill in arts:
        if skill not in ARTS: continue
        requirements = ARTS[skill]["requirements"]
        assert sum(stats.values()) >= requirements["minimum_total"]
        assert all(stats[k] >= v for k, v in requirements["stats"].items())
    assert sum(stats.values()) >= 101 and len(arts) <= 4
    hero = Fighter("도원", stats, weapon, arts, STARTS[start][0])
    boss = Fighter("산적 우두머리", copy.deepcopy(BOSS["stats"]), BOSS["weapon"],
                   ["basic_attack", "basic_defense", "danseok", "hoepung"], STARTS[start][1])
    assert boss.hp == BOSS["max_hp"] == 328
    return hero, boss


def aggregate(rows):
    return {"cases": len(rows), "wins": sum(r["winner"] == "hero" for r in rows),
        "losses": sum(r["winner"] == "boss" for r in rows),
        "draws": sum(r["winner"] == "draw" for r in rows), "timeouts": sum(r["winner"] == "timeout" for r in rows),
        "median_hp": statistics.median(r["hero_hp"] for r in rows),
        "median_time": statistics.median(r["time"] for r in rows),
        "median_top_attack_share": round(statistics.median(r["attack_share"] for r in rows), 3),
        "median_unique_attacks": statistics.median(r["unique_attacks"] for r in rows),
        "actions": dict(sum((Counter(r["actions"]) for r in rows), Counter())),
        "enemy_actions": dict(sum((Counter(r["enemy_actions"]) for r in rows), Counter())),
        "median_guard_saved": statistics.median(r["guard_saved"] for r in rows),
        "median_boss_misses": statistics.median(r["boss_misses"] for r in rows),
        "median_move_qi": statistics.median(r["move_qi_recovered"] for r in rows)}


def suite():
    rows, replays = [], []
    # No numbers are tuned in response to wins/losses. Log every outcome, including stalls.
    for art in [key for key, value in ARTS.items() if value["grade"] == "low"]:
        for policy in ("basic_only", "main_spam", "efficient", "reactive", "read_counter"):
            for start in range(len(STARTS)):
                for style in ("pressure", "cautious", "erratic"):
                    for reaction in (0, 3, 6):
                        for seed in (0, 1, 2):
                            record = start == 0 and style == "pressure" and reaction == 3 and seed == 0
                            sim = Combat(*make_fighters(art, start), policy, style, reaction, seed, record)
                            row = sim.run() | dict(art=art, policy=policy, start=start, enemy_style=style, reaction=reaction, seed=seed, group="single")
                            rows.append(row)
                            if record:
                                replays.append({"title": f'{LABELS[art]} / {policy}', "result": row, "frames": sim.frames, "events": sim.log})
    for art in ("cheongpung", "danseok", "gwanpung", "cheolsan"):
        for policy in ("efficient", "reactive"):
            for start in range(len(STARTS)):
                for style in ("pressure", "cautious", "erratic"):
                    for reaction in (0, 3, 6):
                        for seed in (0, 1, 2):
                            sim = Combat(*make_fighters(art, start, True), policy, style, reaction, seed)
                            rows.append(sim.run() | dict(art=art, policy=policy, start=start, enemy_style=style, reaction=reaction, seed=seed, group="dual"))
    # Diagnostic only: time-based qi instead of action-based, and removing the defensive option.
    for mode in ("clock", "no_guard"):
        for art in ("cheongpung", "gwanpung"):
            for start in range(len(STARTS)):
                for style in ("pressure", "cautious", "erratic"):
                    for seed in (0, 1, 2):
                        sim = Combat(*make_fighters(art, start), "reactive", style, 3, seed,
                                     qi_mode="clock" if mode == "clock" else "action", guard_enabled=mode != "no_guard")
                        rows.append(sim.run() | dict(art=art, policy="reactive", start=start, enemy_style=style, reaction=3, seed=seed, group=mode))
    # Counterfactual isolation only: is a longer HP bar sufficient to create variety?
    # This deliberately breaks the approved HP formula for this diagnostic, not for the main cases.
    for art in ("cheongpung", "danseok", "gwanpung"):
        for policy in ("efficient", "reactive"):
            for start in range(len(STARTS)):
                for style in ("pressure", "cautious", "erratic"):
                    for seed in (0, 1, 2):
                        hero, boss = make_fighters(art, start)
                        boss.hp *= 2
                        sim = Combat(hero, boss, policy, style, 3, seed)
                        rows.append(sim.run() | dict(art=art, policy=policy, start=start, enemy_style=style, reaction=3, seed=seed, group="hp_double"))
    groups = {}
    for row in rows:
        key = f'{row["group"]}/{row["art"]}/{row["policy"]}'
        groups.setdefault(key, []).append(row)
    summary = {key: aggregate(values) for key, values in groups.items()}
    primary_summary = {}
    for key, values in groups.items():
        if key.startswith("single/"):
            primary_summary[key] = aggregate([r for r in values if r["reaction"] == 3])
    sources = {name: hashlib.sha256((ROOT / "godot/data" / (name + ".json")).read_bytes()).hexdigest() for name in FILES}
    result = {"status": "REVIEW ONLY — not live Godot combat or human playtest", "timings": TIMING,
              "enemy": BOSS, "temporary_enemy_skills": ["danseok", "hoepung"],
              "source_sha256": sources,
              "simulator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "summary": summary, "primary_summary": primary_summary, "rows": rows}
    (OUT / "results.json").write_text(json.dumps(result, ensure_ascii=False, indent=2))
    (OUT / "replays.json").write_text(json.dumps({"labels": LABELS, "replays": replays}, ensure_ascii=False, separators=(",", ":")))
    print(f'{len(rows)} cases; {len(replays)} recorded replays')
    for key, value in summary.items():
        print(key, json.dumps(value, ensure_ascii=False))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--suite", action="store_true")
    parser.add_argument("--art", default="cheongpung")
    parser.add_argument("--policy", default="reactive")
    args = parser.parse_args()
    if args.suite:
        suite()
    else:
        sim = Combat(*make_fighters(args.art), policy=args.policy, reaction=3, record=True)
        print(json.dumps(sim.run(), ensure_ascii=False, indent=2))
        for event in sim.log: print(json.dumps(event, ensure_ascii=False))
