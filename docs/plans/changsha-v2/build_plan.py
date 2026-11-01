"""Planning data only. No Godot files, assets, NPCs or game state are changed."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parent
D=dict(name='장사 논리 타일 배치 검토안 v2',size=[48,40],units='one unit = one existing isometric logical tile',coordinate='u right, v down in plan; north=-v (proposed geography)',tile_pixels=[128,64],actor_radius=.15,actor_canvas_height=96,camera_zoom=.85,viewport=[1280,720],speed=4.8,buildings=[],roads=[],zones=[],fences=[],npcs=[])
def building(id,name,kind,r,face='E',art=None):
 x,y,w,h=r
 # Existing painted house threshold is outside its physical footprint.
 door=[x+2.255814,y+1.162791] if art=='house' else [x-.18,y+h/2] if art=='warehouse_back' else {'E':[x+w,y+h/2],'W':[x,y+h/2],'N':[x+w/2,y],'S':[x+w/2,y+h]}[face]
 normal={'E':[1,0],'W':[-1,0],'N':[0,-1],'S':[0,1]}[face]
 approach=[door[i]+normal[i]*.55 for i in range(2)]
 D['buildings'].append(dict(id=id,name=name,kind=kind,rect=r,facing=face,door=door,approach=approach,art=art,art_status='existing exact scale' if art else 'new art needed; footprint provisional'))
def road(id,p,w=1.2,kind='stone'):D['roads'].append(dict(id=id,points=p,width=w,kind=kind))
def zone(id,name,r,kind='common'):D['zones'].append(dict(id=id,name=name,rect=r,kind=kind))
def fence(id,r,gates,owner,thickness=.2):D['fences'].append(dict(id=id,rect=r,gates=gates,owner=owner,thickness=thickness))
def npc(id,role,p,route=None):D['npcs'].append(dict(id=id,role=role,position=p,route=route or []))
D['river']=[[0,0],[4.5,0],[5,9],[4.6,17],[5,25],[4.2,40],[0,40]]
fence('city',[9,7,35,28],[dict(side='W',at=20,width=3),dict(side='E',at=20,width=3),dict(side='N',at=25,width=3),dict(side='S',at=25,width=3)],'city',.35)
# Ground uses first; agricultural clusters do not alternate rice and dry beds.
D['paddies']=[[[11,1],[17,1.5],[17.5,4.4],[11,5]],[[18,1],[22,1],[22.7,4.8],[18,4.4]]]
D['dry_fields']=[[[29,.8],[34,1.2],[34,4.6],[28.5,4.4]]]
D['irrigation']=[[4.6,3],[10,3],[10,5.6],[23,5.6]]
road('bank',[[7,0],[7,40]],1.0,'dirt')
road('dock',[[4.5,20],[8.1,20]],3,'wood');road('west_entry',[[8.1,20],[9,20]],3,'dirt')
road('freight',[[9,20],[44,20]],2.6)
road('east_exit',[[44,20],[46,20],[48,17]],2.6,'dirt')
road('spine',[[25,7],[25,35]],2.6)
road('north_exit',[[25,0],[25,7]],2.6,'dirt');road('south_exit',[[25,35],[25,40]],2.6,'dirt')
road('north_cross',[[11.5,9.5],[25,9.5]],1.2)
road('dock_warehouse_lane',[[11.5,9.5],[11.5,20]],1.2)
road('warehouse_gate_approach',[[11.5,13.25],[15.27,13.25]],1.2)
road('warehouse_service',[[15,13.25],[15,16.85],[15.27,16.85]],1.0)
road('house_rear',[[19.3,11.1],[23.25,11.1]],.9)
road('house_front',[[23.25,10],[23.25,20]],1.2)
road('market_a',[[31.2,12.5],[31.2,20]],1.5)
road('market_b',[[36.5,12.5],[36.5,20]],1.2)
# Civic courts are reached from the market; no public road cuts through a private yard.
road('office_entry',[[39.5,13],[39.5,20]],1.2)
road('work_lane',[[17,20],[17,33.7]],1.2)
road('south_cross',[[11.5,33.7],[42.5,33.7]],1.2)
road('inn_entry',[[25,28],[23,28]],1.2)
for u in [31,36,42.2]:road('housing_'+str(u),[[u,22.5],[u,33.7]],1.1)
road('housing_cross',[[26.3,28.3],[42.2,28.3]],1.2)
road('housing_north',[[26.3,22.5],[42.2,22.5]],1.2)
road('farm_lane',[[25,6],[38,6],[38,3]],1.2,'dirt')
zone('dock_wait','나루 대기·하역',[5.3,17,3,2]);zone('load','창고 하역마당',[13.2,11,2.3,7.5],'work')
zone('market','상점 앞 공동 공간',[27,12.5,13,7],'common')
zone('martial','연무장',[31.5,8.6,3.8,3.1],'public')
zone('office','관아 앞마당',[36.5,13.1,6,2.2],'public')
zone('craft','열린 작업장',[15.8,23,3,8],'work')
zone('house_front','민가 앞자리',[19.3,10.6,4.6,5])
zone('inn','객잔 앞 쉼터',[23,26,1,4])
zone('waiting','장날 집결·대기',[19.3,22.1,4,2.8])
zone('housing','주거 공동 생활 공간',[27,22.5,16,11.7])
zone('well','공동 우물 주변',[37,27.5,1.2,1.4])
zone('farm','농가 앞자리',[37,2,1.5,3])
# Compact modest buildings use prototype footprints. Public facilities need new art later.
building('W1','곡물창고1','warehouse',[16,12,1.5,2.5],'W','warehouse_back')
building('W2','곡물창고2','warehouse',[16,15.6,1.5,2.5],'W','warehouse_back')
building('H1','창고지기 민가','house',[20,12,2,3],'E','house')
building('S1','잡화점','market',[28.5,13.8,1.5,2.5])
building('S2','곡물상','market',[28.5,17,1.5,2.5])
building('S3','약재점','market',[33,14,1.5,2.5],'W')
building('S4','포목점','market',[40.2,16.3,1.5,2.5],'W')
building('O1','관아','office',[38,10.2,3,2.8],'S')
building('M1','무관','martial',[28,8.7,2.5,3.2])
building('C1','철공방','workshop',[13.2,23.4,2,3],'E','house')
building('C2','목공방','workshop',[13,28.8,2,3],'E','house')
building('I1','객잔','inn',[20,26,3,4])
building('D1','나루 관리소','warehouse',[10.5,23,1.5,2.5])
for id,name,x,y in [('H2','민가2',28,24),('H3','민가3',32.5,24),('H4','민가4',38,24),('H5','민가5',28.2,30.2),('H6','민가6',33,30.1),('H7','민가7',39,30.3)]:building(id,name,'house',[x,y,2,3],'E','house')
building('F1','외곽 농가','house',[35,2,2,3],'E','house')
# Real boundary ownership, actual open gates, not arbitrary floating wall segments.
fence('warehouse_yard',[13,10.5,5.5,8.3],[dict(side='W',at=13.25,width=1.2)],'W1,W2')
fence('martial_yard',[27.5,8.2,8.2,4],[dict(side='S',at=32.8,width=1.4)],'M1')
fence('office_yard',[36,8.5,7,7],[dict(side='S',at=39.5,width=1.4)],'O1')
fence('private_house',[32,23,3.7,4.4],[dict(side='E',at=25.162791,width=1.15)],'H3')
road('martial_gate',[[31.2,12.5],[32.8,12.5],[32.8,10.3],[30.5,10.3]],1.1)
# Every actual door gets an explicit approach path to a common lane, not a wishful arrow.
for b in D['buildings']:
 x,y,w,h=b['rect'];a=b['approach'];id=b['id']
 if id.startswith('W'):anchor=[15,a[1]]
 elif id=='H1':anchor=[23.25,a[1]]
 elif id in ['S1','S2']:anchor=[31.2,a[1]]
 elif id in ['S3','S4','S5']:anchor=[36.5 if id!='S3' else 31.2,a[1]]
 elif id=='O1':anchor=[39.5,15.5]
 elif id=='M1':anchor=[32.8,10.3]
 elif id.startswith('C'):anchor=[17,a[1]]
 elif id=='I1':anchor=[25,a[1]]
 elif id=='D1':anchor=[12.55,20];road('dock_office_side',[[12.55,20],[12.55,a[1]]],.9)
 elif id=='F1':anchor=[38,a[1]]
 else:anchor=[31 if x<30 else 36 if x<36 else 42.2,a[1]]
 b['road_anchor']=anchor;road('door_'+id,[anchor,a,b['door']],.9)
# Resident points are on the side, while porter traffic has meaningful endpoints.
npc('N01','약재 상인',[32,14.7]);npc('N02','철공 장인',[16.1,24.3]);npc('N03','무관 교관',[34.8,10.5]);npc('N04','객잔지기',[23.8,26.6]);npc('N05','동문 문지기',[43,18.1]);zone('guard','문지기 대기',[42,17.5,1.5,1.5])
npc('N06','나루 짐꾼',[11.5,18.4],[[7,18],[7,20],[11.5,20],[11.5,13.25],[14.1,13.25],[15.2,13.25]])
npc('N07','창고지기',[14.6,17.8]);npc('N08','곡물상',[30.5,18.3]);npc('N09','농부',[37.6,5.4]);zone('farm_wait','농가 생활 자리',[37,5,1.5,1])
npc('N10','골목 주민',[40.9,28.3],[[31,28.3],[36,28.3],[42.2,28.3],[42.2,32.6]])
npc('N11','민가 주민',[23,15.0]);npc('N12','관아 포졸',[42,14.5])
D['detail_bounds']=[10,9.5,17,12.5]
D['review_loop']=[[25,34],[25,20],[11.5,20],[11.5,9.5],[25,9.5],[25,20],[42.2,20],[42.2,28.3],[25,28.3],[25,34]]
D['representative_cases']=[dict(id='front',label='A 문 앞: 인물이 건물 앞',position=[22.9,13.162791]),dict(id='rear',label='B 뒤 골목: 가림 확인',position=[20.8,11.55]),dict(id='side',label='C 건물 옆: 정렬 전환 확인',position=[19.55,13.5]),dict(id='gate',label='D 대문: 기둥 충돌·상부 가림',position=[13.1,13.25])]
(ROOT/'plan.json').write_text(json.dumps(D,ensure_ascii=False,indent=2)+'\n')
print('PLAN',D['size'],len(D['buildings']),'buildings;',len(D['npcs']),'NPC candidates')
