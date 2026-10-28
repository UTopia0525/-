"""Render exact combat footprints as diagrams, directly from live JSON data.

Run from any directory: python docs/martial-arts/range-diagrams/render.py
Requires matplotlib and Pillow. This is documentation artwork, not runtime UI.
"""
import json
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import font_manager
from matplotlib.patches import Rectangle, Circle, Polygon, FancyArrowPatch
from matplotlib.offsetbox import AnnotationBbox, OffsetImage
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
DATA = ROOT / 'godot/data'
FONT = ROOT / 'godot/assets/fonts/NanumMyeongjo-Regular.ttf'
font_manager.fontManager.addfont(str(FONT))
plt.rcParams['font.family'] = font_manager.FontProperties(fname=FONT).get_name()
plt.rcParams['axes.unicode_minus'] = False
T = json.loads((DATA / 'martial_tactics.json').read_text())['entries']
ARTS = {}
for source in ['basic_martial_arts', 'alliance_martial_arts', 'quest_martial_arts', 'support_martial_arts']:
    ARTS.update(json.loads((DATA / f'{source}.json').read_text()))
ARTS.update({'basic_attack': {'name': '기본공격', 'grade': 'basic', 'weapon_style': 'sword'},
             'basic_defense': {'name': '기본방어', 'grade': 'basic', 'weapon_style': 'support'}})
SHEET = Image.open(ROOT / 'godot/assets/battle/hero-poses.png').convert('RGBA')
FRAMES = json.loads((ROOT / 'godot/assets/battle/frames.json').read_text())['hero']['frames']
BG, PANEL, GOLD, INK = '#101b24', '#192b34', '#cdb983', '#f2ead9'
RED, CYAN, PUSH, BLUE = '#f18b79', '#6de0d3', '#f9cc71', '#86c9f4'


def arrow(ax, start, end, color, style='-|>', dashed=False, width=2.2):
    ax.add_patch(FancyArrowPatch(start, end, arrowstyle=style,
        mutation_scale=15, linewidth=width, color=color, zorder=12,
        linestyle='--' if dashed else '-', shrinkA=6, shrinkB=6))


def sprite(ax, point, kind, alpha=1.0):
    col = {'sword': 0, 'saber': 1, 'spear': 2}.get(kind, 3)
    x, y, w, h = FRAMES[str(col)]['region']
    frame = SHEET.crop((x, y, x+w, y+h))
    box = OffsetImage(frame, zoom=0.26, alpha=alpha)
    ax.add_artist(AnnotationBbox(box, (point[0], point[1]-.28), frameon=False, zorder=9))


def shield(ax, x, y, size=.24):
    ax.add_patch(Polygon([(x-size,y-size), (x+size,y-size),
        (x+size*.85,y+size*.5), (x,y+size*1.2), (x-size*.85,y+size*.5)],
        facecolor='#235570', edgecolor=BLUE, linewidth=1.6, zorder=14))
    ax.text(x, y, '20%', color='#e6f8ff', size=9, ha='center', va='center', zorder=15)


def draw(ax, id):
    art, t = ARTS[id], T[id]
    ax.set_facecolor(PANEL)
    ax.set_xlim(-.65, 6.65); ax.set_ylim(5.0, -1.25)
    ax.set_aspect('equal'); ax.axis('off')
    # All cards face right. Start and destination are separate for composite moves.
    start = (2, 2)
    caster = (2 + t['advance'], 2)
    end = (caster[0] - t['retreat'], caster[1])
    cells = [(caster[0]+x, caster[1]+y) for x,y in t['attack_offsets']]
    assert len(cells) == len(set(cells))
    assert all(0 <= x < 7 and 0 <= y < 5 for x,y in cells)
    for y in range(5):
        for x in range(7):
            hit = (x,y) in cells
            ax.add_patch(Rectangle((x-.48,y-.48),.96,.96,
                facecolor='#a54d46' if hit else '#21343b',
                edgecolor=RED if hit else '#526066',linewidth=1.5 if hit else .7,zorder=1))
            if hit:
                # Repeated slashes read as an active attack area, without implying
                # multiple hits or extending outside the legal tile footprint.
                for d in [-.2,.05,.3]:
                    ax.plot([x+d-.12,x+d+.08],[y+.2,y-.15], color='#ffd5ae',
                            linewidth=1.3, alpha=.8,zorder=3)
    if t['advance']:
        sprite(ax,start,art['weapon_style'],.23)
        arrow(ax,(start[0],start[1]+.33),(caster[0],caster[1]+.33),CYAN)
        ax.text(start[0],start[1]+.72,'1',color=CYAN,ha='center',size=13)
        ax.text(caster[0],caster[1]+.72,'2',color=CYAN,ha='center',size=13)
    ax.add_patch(Circle(caster,.33,edgecolor=CYAN,facecolor='#23636a',linewidth=2,zorder=4))
    sprite(ax,caster,art['weapon_style'])
    arrow(ax,(caster[0]+.2,caster[1]-.86),(caster[0]+.8,caster[1]-.86),INK,width=1.2)
    if t['retreat']:
        sprite(ax,end,art['weapon_style'],.25)
        arrow(ax,(caster[0],caster[1]+.37),(end[0],end[1]+.37),CYAN,dashed=True)
        ax.text(caster[0],caster[1]+.74,'1',color=CYAN,ha='center',size=13)
        ax.text(end[0],end[1]+.74,'2',color=CYAN,ha='center',size=13)
    if t['push']:
        # Show the same push vector on every affected cell, not just one target.
        for x,y in cells:
            ax.add_patch(Circle((x,y+.08),.105,facecolor=PUSH,edgecolor='#fff0b9',zorder=11))
            arrow(ax,(x+.08,y+.13),(x+1,y+.13),PUSH,width=2.1)
    if (art['weapon_style']=='sword' and id!='basic_attack') or id in ['basic_defense','josik_suwon']:
        shield(ax,caster[0]-.64,caster[1]-.38)
    if id=='josik_suwon':
        for r in [.6,.82,1.04]:
            ax.add_patch(Circle(caster,r,fill=False,edgecolor=CYAN,linewidth=1.5,alpha=.8,zorder=8))
        ax.text(4.15,1.5,'내기 + 내공×2',color=CYAN,size=12,ha='center')
        ax.text(4.15,2.12,'●  ●  ●',color=GOLD,size=17,ha='center')
        ax.text(4.15,2.62,'재사용 대기: 자기 행동 3번',color=GOLD,size=8.5,ha='center')
    grades={'basic':'기본','introductory':'입문','low':'하급','intermediate':'중급'}
    kinds={'sword':'검','saber':'도','spear':'창','fist':'권','palm':'장','support':'공통'}
    ax.text(-.42,-.86,art['name'],color=INK,size=19,weight='bold',ha='left')
    kind = '공통' if id in ['basic_attack','basic_defense'] else kinds[art['weapon_style']]
    ax.text(6.4,-.86,f"{grades[art['grade']]} · {kind}",
        color=GOLD,size=10,ha='right')
    ax.plot([-.45,6.45],[-.59,-.59],color=GOLD,alpha=.55,linewidth=.8)


def page(ids, title, filename):
    fig,axes=plt.subplots(3,3,figsize=(16,14.7),dpi=140,facecolor=BG)
    fig.subplots_adjust(left=.035,right=.975,bottom=.085,top=.91,wspace=.12,hspace=.18)
    fig.text(.045,.963,title,color=INK,size=25,weight='bold')
    fig.text(.045,.934,'7 × 5  |  실제 공격 칸 데이터 기준  |  시전 방향 →',color=GOLD,size=12)
    for ax,id in zip(axes.flat,ids): draw(ax,id)
    fig.text(.045,.052,'붉은 칸  공격 범위     청록 화살표  시전자 이동     황금 화살표  적 밀침',color=INK,size=12)
    fig.text(.045,.028,'1 → 2 행동 순서    점선: 공격 후 후퇴    방패: 피해 20% 감소    같은 적에게는 1회 타격',color='#a7bdc2',size=10)
    fig.savefig(OUT/filename,facecolor=BG,dpi=140)
    plt.close(fig)


page(['samjae','cheongpung','yusu','danseok','hoepung','gwanpung','yeonhwan','cheolsan','ungi'],
     '무공 범위 도해 · 입문 / 하급','introductory-low.png')
page(['hoeryu','paak','gwanak','banseok','jungun','swaerang','josik_suwon','basic_attack','basic_defense'],
     '무공 범위 도해 · 중급 / 기본 행동','intermediate-basic.png')
print('Rendered 16 martial arts + 2 basic actions from live tactics data.')
