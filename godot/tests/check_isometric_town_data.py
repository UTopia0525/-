"""Bounded read-only audit of the isolated town. No third-party modules or image loading."""
import copy
import json
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ISO = ROOT / "prototypes/isometric"
ID = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key: " + key)
        result[key] = value
    return result


def read(path):
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_object)


def fixture():
    shop = (ISO / "iso_town_shop.gd").read_text(encoding="utf-8")
    owner = (ISO / "iso_town_errands.gd").read_text(encoding="utf-8")
    item_id = re.search(r'const\s+ITEM\s*=\s*"([^"]+)"', shop).group(1)
    return dict(outside=read(ISO / "changsha-layout.json"), room=read(ISO / "room-layout.json"),
                quests=read(ISO / "town-quests.json"), art=read(ISO / "assets/manifest.json"),
                dialogue=read(ISO / "dialogues.json"), basics=read(ROOT / "data/basic_npc_portraits.json")["entries"],
                items=read(ROOT / "data/low_grade_elixirs.json"), icons=read(ROOT / "data/icon_manifest.json"),
                stock=dict(id=item_id, money=int(re.search(r"var\s+money\s*=\s*(-?\d+)", owner).group(1))))


def number(x):
    return type(x) in (int, float) and math.isfinite(x)


def vector(value, n):
    return isinstance(value, list) and len(value) == n and all(number(x) for x in value)


def validate(d):
    errors = []

    def error(code, where):
        errors.append(code + ": " + where)

    def file(path, where):
        if not isinstance(path, str) or not path.startswith("res://") or not (ROOT / path[6:]).is_file():
            error("missing_file", where)

    objects = {}
    npc_ids = {"TownMerchant"}  # Constructed in iso_town_world.gd; actual registry is also checked in Godot.
    for place in ("outside", "room"):
        layout = d[place]
        size = layout.get("size")
        if not vector(size, 2) or min(size) <= 0:
            error("invalid_geometry", place + ".size")
            continue
        paving=layout.get("paving",[])
        for index in layout.get("public_paving",[]):
            if type(index) is not int or not 0<=index<len(paving):error("paving_reference",place)
        plot_ids={plot["id"] for plot in layout.get("plots",[])}
        seen = set()
        objects[place] = {}
        for kind in ("props", "walls", "patrols"):
            if not isinstance(layout.get(kind), list):
                error("missing_field", place + "." + kind)
                continue
            for obj in layout[kind]:
                if not isinstance(obj, dict):
                    error("missing_field", place+"."+kind); continue
                key = obj.get("id", "")
                if not isinstance(key, str) or not ID.fullmatch(key):
                    error("invalid_id", place)
                    continue
                if key in seen:
                    error("duplicate_id", place + "." + key)
                seen.add(key)
                if kind == "patrols":
                    if key in npc_ids:
                        error("duplicate_id", key)
                    npc_ids.add(key)
                    route = obj.get("route")
                    if not isinstance(route, list) or len(route) < 2 or not all(vector(p, 2) and all(0 <= p[i] <= size[i] for i in range(2)) for p in route):
                        error("invalid_route", key)
                    continue
                rect = obj.get("rect")
                if not vector(rect, 4) or min(rect[2:]) <= 0 or any(rect[i] < 0 or rect[i] + rect[i+2] > size[i]+1e-6 for i in range(2)):
                    error("invalid_geometry", key)
                    continue
                if obj.get("plot") and obj["plot"] not in plot_ids:error("plot_reference",key)
                if kind == "walls":
                    # Detect collisions between explicit IDs and generated wall-segment IDs.
                    for i in range(math.ceil(max(rect[2:]) / .75)):
                        generated = key + "_" + str(i)
                        if generated in seen or any(p.get("id") == generated for p in layout["props"]):
                            error("duplicate_id", generated)
                    continue
                objects[place][key] = obj
                if obj.get("kind") == "building":
                    entry = obj.get("entrance", {})
                    for field in ("threshold", "facing", "approach", "road_anchor"):
                        if not vector(entry.get(field), 2):
                            error("missing_field", key + "." + field)
                    if entry.get("interior"):
                        file(entry["interior"], key + ".interior")
                        if entry["interior"]!="res://prototypes/isometric/room.tscn":error("interior_reference",key)
                    if obj.get("art", obj["kind"]) not in d["art"]["buildings"]:
                        error("art_reference", key)
        spawn = layout.get("spawn")
        if not vector(spawn, 2) or not all(0 <= spawn[i] <= size[i] for i in range(2)):
            error("invalid_geometry", place + ".spawn")
    if "lane_house" not in objects.get("outside", {}):
        error("entrance_reference", "lane_house")
    for key, q in d["quests"].items():
        if not isinstance(key, str) or not ID.fullmatch(key):
            error("invalid_id", str(key))
        key = str(key)
        if not isinstance(q, dict):
            error("missing_field", str(key)); continue
        for field in ("title", "giver", "actor", "place", "point", "approach", "label", "lines", "target_id", "objectives"):
            if field not in q:
                error("missing_field", key + "." + field)
        if not isinstance(q.get("giver"), str) or q["giver"] not in npc_ids:
            error("giver_reference", key)
        if not isinstance(q.get("actor"), str) or q["actor"] not in d["dialogue"]["actors"]:
            error("actor_reference", key)
        place = q.get("place")
        target_id=q.get("target_id")
        target = objects.get(place, {}).get(target_id) if isinstance(place,str) and isinstance(target_id,str) else None
        if target is None:
            error("target_reference", key)
        for field in ("point", "approach"):
            if not vector(q.get(field), 2):
                error("invalid_geometry", key + "." + field)
            elif isinstance(place,str) and place in objects and not all(0 <= q[field][i] <= d[place]["size"][i] for i in range(2)):
                error("invalid_geometry", key + "." + field)
        if target and vector(q.get("point"), 2) and vector(target.get("rect"), 4):
            p, r = q["point"], target["rect"]
            if not all(r[i]-.01 <= p[i] <= r[i]+r[i+2]+.01 for i in range(2)):
                error("target_position", key)
        objectives = q.get("objectives", {})
        if not isinstance(objectives, dict):
            error("invalid_objectives", key); objectives = {}
        for place in ("outside", "room"):
            if not isinstance(objectives.get(place), str) or not objectives[place].strip():
                error("invalid_objectives", key + "." + place)
        lines = q.get("lines", {})
        if not isinstance(lines, dict):
            error("missing_field", key+".lines"); lines={}
        for state in ("available", "active", "ready", "completed", "accept", "decline", "inspect"):
            if not isinstance(lines.get(state), list) or not lines[state] or not all(isinstance(s, str) and s.strip() for s in lines[state]):
                error("missing_field", key + ".lines." + state)
    for actor in d["dialogue"]["actors"].values():
        if "portrait" in actor:
            file(actor["portrait"], "portrait")
        else:
            portrait = d["basics"].get(actor.get("basic_portrait"), {})
            file(portrait.get("path"), "basic_portrait")
    # Merchant actor is authored in the trial dialogue script, not dialogues.json.
    file(d["basics"].get("male_common_b", {}).get("path"), "merchant portrait")
    for info in d["art"]["buildings"].values():
        file(info.get("texture"), "art texture")
        if not vector(info.get("region"), 4) or min(info["region"][2:]) <= 0:
            error("invalid_geometry", "art region")
    for kind in ("hero","npc"):
        for face in ("front","back"):
            info=d["art"][kind].get(face,{})
            file(info.get("texture"),kind+"."+face)
            if not vector(info.get("region"),4) or min(info["region"][2:])<=0:
                error("invalid_geometry",kind+"."+face)
    stock = d["stock"]
    item = d["items"].get(stock.get("id"))
    if item is None:
        error("item_reference", "stock")
    elif type(item.get("price")) is not int or item["price"] <= 0:
        error("invalid_price", "stock")
    if item:
        for field in ("name","description","permanent_stat_gains","max_lifetime_uses"):
            if field not in item:error("missing_field","item."+field)
    if type(stock.get("money")) is not int or stock["money"] < 0:
        error("invalid_money", "stock")
    icon = d["icons"].get(stock.get("id"))
    if not icon:
        error("icon_reference", "stock")
    else:
        file(icon.get("path", "res://assets/icons/" + icon.get("atlas", "") + ".png"), "item icon")
    return errors


class TownDataAudit(unittest.TestCase):
    def test_real_data(self):
        self.assertEqual(validate(fixture()), [])

    def test_duplicate_json_keys(self):
        with self.assertRaises(ValueError):
            json.loads('{"quest":1,"quest":2}', object_pairs_hook=unique_object)

    def test_faults_on_memory_copies(self):
        base = fixture()
        cases = []
        def case(code, mutate):
            data = copy.deepcopy(base); mutate(data); cases.append((code, data))
        case("duplicate_id", lambda d: d["outside"]["props"].append(copy.deepcopy(d["outside"]["props"][0])))
        case("duplicate_id", lambda d: d["outside"]["patrols"].append(copy.deepcopy(d["outside"]["patrols"][0])))
        case("duplicate_id", lambda d: d["outside"]["props"][0].update(id="house_north_0"))
        case("giver_reference", lambda d: d["quests"]["iso_errand"].update(giver="Missing"))
        case("actor_reference", lambda d: d["quests"]["iso_errand"].update(actor="Missing"))
        case("target_reference", lambda d: d["quests"]["iso_errand"].update(target_id="Missing"))
        case("target_reference", lambda d: d["room"]["props"].pop(0))
        case("target_position", lambda d: d["quests"]["iso_errand"].update(point=[7, 5]))
        case("missing_field", lambda d: d["quests"]["iso_errand"].pop("title"))
        case("missing_field", lambda d: d["quests"]["iso_errand"].pop("objectives"))
        case("invalid_objectives", lambda d: d["quests"]["iso_errand"].update(objectives=None))
        case("invalid_objectives", lambda d: d["quests"]["iso_errand"]["objectives"].pop("room"))
        case("invalid_objectives", lambda d: d["quests"]["iso_errand"]["objectives"].update(outside=" "))
        case("invalid_objectives", lambda d: d["quests"]["iso_errand"]["objectives"].update(room=17))
        case("missing_field", lambda d: d["quests"]["iso_errand"]["lines"].pop("ready"))
        case("giver_reference", lambda d: d["quests"]["iso_errand"].update(giver=[]))
        case("target_reference", lambda d: d["quests"]["iso_errand"].update(target_id=[]))
        case("missing_field", lambda d: d["quests"]["iso_errand"].update(lines=None))
        case("missing_field", lambda d: d["items"][d["stock"]["id"]].pop("description"))
        case("paving_reference", lambda d: d["outside"]["public_paving"].append(999))
        case("plot_reference", lambda d: d["outside"]["walls"][0].update(plot="Missing"))
        case("interior_reference", lambda d: next(p for p in d["outside"]["props"] if p["id"]=="lane_house")["entrance"].update(interior="res://scenes/main.tscn"))
        case("invalid_route", lambda d: d["outside"]["patrols"][0].update(route=[]))
        case("invalid_geometry", lambda d: d["outside"]["props"][0].update(rect=[0, 0, 0, 2]))
        case("invalid_geometry", lambda d: d["outside"]["props"][0].update(rect=[99, 0, 1, 2]))
        case("invalid_geometry", lambda d: d["quests"]["iso_errand"].update(point=[float("nan"), 1]))
        case("invalid_geometry", lambda d: d["outside"].update(spawn=["x", 1]))
        case("missing_file", lambda d: next(p for p in d["outside"]["props"] if p["id"]=="lane_house")["entrance"].update(interior="res://missing.tscn"))
        case("missing_file", lambda d: d["art"]["buildings"]["house"].update(texture="res://missing.png"))
        case("item_reference", lambda d: d["stock"].update(id="Missing"))
        case("invalid_money", lambda d: d["stock"].update(money=-1))
        for price in (-100, 0, 1.5, "100", float("nan")):
            case("invalid_price", lambda d, value=price: d["items"][d["stock"]["id"]].update(price=value))
        for code, data in cases:
            with self.subTest(code=code):
                self.assertTrue(any(e.startswith(code+":") for e in validate(data)), (code, validate(data)))
        print("MEMORY_FAULT_CASES", len(cases))


if __name__ == "__main__":
    unittest.main(verbosity=2)
