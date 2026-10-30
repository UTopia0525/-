"""Numerical review catalogue. No runtime items, learning rules or art assets added."""
import copy
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
DATA=ROOT/'godot/data'
FILES=('basic_martial_arts','alliance_martial_arts','quest_martial_arts','support_martial_arts','martial_tactics','weapons','tutorial_enemy')
ORIGINAL={}
for name in FILES[:4]: ORIGINAL.update(json.loads((DATA/(name+'.json')).read_text()))
TACTICS=json.loads((DATA/'martial_tactics.json').read_text())['entries']
WEAPONS=json.loads((DATA/'weapons.json').read_text())
TIMINGS={
 'move':(3,5,2),'basic_attack':(3,2,5),'basic_defense':(2,6,2),
 'samjae':(5,2,5),'cheongpung':(6,4,5),'yusu':(5,3,8),
 'danseok':(9,3,9),'hoepung':(10,5,10),'gwanpung':(7,2,8),'yeonhwan':(9,5,8),
 'cheolsan':(6,3,8),'ungi':(8,4,8),
 'hoeryu':(6,4,8),'paak':(10,4,12),'gwanak':(7,3,10),
 'banseok':(7,4,11),'jungun':(8,4,12),'swaerang':(12,5,13),'josik_suwon':(4,10,4),
 'yuha':(7,4,9),'bunag':(13,5,14),'pajin':(8,3,11),
 'geumgang':(8,4,16),'jungcheon':(11,5,14),'cheongwang':(15,5,14),'ildodangang':(17,6,15),
}
COSTS=dict(samjae=25,cheongpung=40,yusu=45,danseok=55,hoepung=60,gwanpung=60,yeonhwan=70,cheolsan=55,ungi=55,
           hoeryu=70,paak=80,gwanak=85,banseok=75,jungun=80,swaerang=80,josik_suwon=0,
           yuha=240,bunag=360,pajin=260,geumgang=340,jungcheon=320,cheongwang=380,ildodangang=420)
# Separate alternative to the current power coefficients. Existing values stay in ORIGINAL.
GRADED={
 'samjae':(20,2,1),'cheongpung':(0,3.5,.8),'yusu':(0,3,1.2),
 'danseok':(0,6,1),'hoepung':(0,3.5,1),'gwanpung':(200,1.5,.5),'yeonhwan':(150,1.2,.4),
 'cheolsan':(0,2,6),'ungi':(0,1.5,5),
 'hoeryu':(0,5.5,1.5),'paak':(0,8,2),'gwanak':(300,2,.6),
 'banseok':(0,3,9),'jungun':(0,2,7),'swaerang':(0,7,1.5),
}
UPPER={
 'yuha':dict(name='유하검법',weapon_style='sword',required_weapon_type='sword',base_damage=0,damage_coefficients=dict(strength=9,inner=2),
             attack_offsets=[[1,-1],[1,0],[1,1],[2,0],[3,0]],description='넓은 근거리 검로와 긴 정면 찌르기를 잇는 상급 검법.'),
 'bunag':dict(name='분악도법',weapon_style='saber',required_weapon_type='saber',base_damage=0,damage_coefficients=dict(strength=15,inner=3),
             attack_offsets=[[1,0],[2,0],[3,0]],description='길고 좁은 정면을 크게 내려베는 강공.'),
 'pajin':dict(name='파진관운창법',weapon_style='spear',required_weapon_type='spear',base_damage=950,damage_coefficients=dict(strength=2.5,inner=.8),
             attack_offsets=[[2,0],[3,0]],description='먼 직선을 꿰뚫는 높은 고정 위력의 창법. 바로 붙으면 닿지 않는다.'),
 'geumgang':dict(name='금강쇄심권',weapon_style='fist',required_weapon_type='none',base_damage=0,damage_coefficients=dict(strength=5,inner=17),
             attack_offsets=[[1,0]],advance=1,push=1,description='한 걸음 파고들어 내기를 터뜨리고 상대를 밀어낸다.'),
 'jungcheon':dict(name='중천진악장',weapon_style='palm',required_weapon_type='none',base_damage=0,damage_coefficients=dict(strength=3,inner=14),
             attack_offsets=[[1,-1],[1,0],[1,1],[2,0]],push=1,description='정면에 넓은 장력을 펼쳐 가까운 적들을 밀어낸다.'),
 'cheongwang':dict(name='천광일섬',weapon_style='sword',required_weapon_type='sword',base_damage=0,damage_coefficients=dict(strength=16,inner=4),
             attack_offsets=[[2,0],[3,0]],finisher=True,description='긴 준비 뒤 먼 정면을 가르는 검의 절초.'),
 'ildodangang':dict(name='일도단강',weapon_style='saber',required_weapon_type='saber',base_damage=0,damage_coefficients=dict(strength=17,inner=3),
             attack_offsets=[[1,-1],[1,0],[1,1],[2,0]],finisher=True,description='많은 내기를 모아 정면을 넓게 끊는 도의 절초.'),
}
STYLE_ARTS={
 'sword':dict(low='cheongpung',mid='hoeryu',upper='yuha',finisher='cheongwang'),
 'saber':dict(low='danseok',mid='paak',upper='bunag',finisher='ildodangang'),
 'spear':dict(low='gwanpung',mid='gwanak',upper='pajin'),
 'fist':dict(low='cheolsan',mid='banseok',upper='geumgang'),
 'palm':dict(low='ungi',mid='jungun',upper='jungcheon'),
}

def catalogue(mode='graded'):
    result=copy.deepcopy(ORIGINAL)
    for key,definition in UPPER.items():
        result[key]=copy.deepcopy(definition)|dict(grade='upper',status='TEST ONLY',requirements={'stats':{},'minimum_total':0})
    for key,d in result.items():
        if mode=='graded' and key in GRADED:
            fixed,strength,inner=GRADED[key]
            d['base_damage']=fixed;d['damage_coefficients']=dict(strength=strength,inner=inner)
        d['qi_cost']=COSTS[key];d['timing']=list(TIMINGS[key])
        tactic=TACTICS.get(key,{})
        for field,default in [('attack_offsets',[]),('advance',0),('retreat',0),('push',0)]:
            d[field]=copy.deepcopy(d.get(field,tactic.get(field,default)))
        d['kind']='support' if key=='josik_suwon' else 'attack'
    return result

FORMULAS={
 'fixed80':lambda i:80,
 'floor80_20_2I':lambda i:max(80,20+2*i),
 'floor80_40_2I':lambda i:max(80,40+2*i),
 'floor80_60_2I':lambda i:max(80,60+2*i),
 'floor80_40_1.5I':lambda i:max(80,int(40+1.5*i)),
 'floor80_40_2.5I':lambda i:max(80,int(40+2.5*i)),
}

if __name__=='__main__':
    here=Path(__file__).resolve().parent
    (here/'catalogue.json').write_text(json.dumps(dict(status='REVIEW ONLY; no game registration',current=ORIGINAL,graded=catalogue(),timings=TIMINGS),ensure_ascii=False,indent=2))
