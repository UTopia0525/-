import json
from pathlib import Path
out=Path('godot/assets/maps/wuchang')
d={'name':'무창','historical_note':'명 초기 무창을 모티프로 한 가상 배치. 남쪽 육로로 입성하며 NPC·본편 이동 연결은 배치 승인 후 추가한다.','art_size':[2048,1536],'world_size':[8192,6144],'spawn':[1100,1490],'walk_bounds':[210,60,1750,1470],'alliance_bounds':[930,85,1000,820], 'npcs':[], 'objects':[], 'roads':[], 'districts':[], 'landmarks':[]}
def obj(id,prefab,r):d['objects'].append({'id':id,'prefab':prefab,'rect':r})
def road(points,width,kind='earth'):d['roads'].append({'points':points,'width':width,'kind':kind})
def district(id,name,r,label):d['districts'].append({'id':id,'name':name,'rect':r,'label':label})
def landmark(id,name,p):d['landmarks'].append({'id':id,'name':name,'point':p})
def row(prefix,x0,x1,y,gate=None):
 # A gap at a gate uses its actual pillar footprint, no hidden wall across passage.
 i=0;x=x0
 while x<x1:
  end=min(x+70,x1)
  segments=[(x,end)]
  if gate:
   a,b=gate
   segments=[(l,h) for l,h in [(x,min(end,a)),(max(x,b),end)] if h-l>4]
  for l,h in segments:obj(f'{prefix}_{i}','wall_h',[l,y,h-l,42]);i+=1
  x=end

def col(prefix,x,y0,y1,gap=None):
 i=0;y=y0
 while y<y1:
  end=min(y+58,y1);segments=[(y,end)]
  if gap:
   a,b=gap;segments=[(l,h) for l,h in [(y,min(end,a)),(max(y,b),end)] if h-l>4]
  for l,h in segments:obj(f'{prefix}_{i}','wall_v',[x,l,23,h-l]);i+=1
  y=end
# Arteries: southern road ends at a broad plaza; east branch reaches alliance gate.
road([[1100,1536],[1100,950],[1100,870]],58)
road([[215,945],[1110,945],[1940,945]],58)
road([[1110,875],[1480,875],[1480,785]],52,'stone')
road([[535,110],[535,1410]],37)
road([[255,565],[870,565],[870,945]],35)
road([[260,1225],[1870,1225]],38)
road([[780,640],[780,1400]],32)
road([[1710,950],[1710,1415]],36)
road([[1100,1090],[1400,1090]],30)
# Alliance own courtyards, separated buildings, broad open central axis.
road([[1480,805],[1480,310]],80,'stone')
road([[1030,580],[1830,580]],42,'stone')
road([[1050,355],[1840,355]],36,'stone')
for args in [('harbor','장강 나루·하역장',[210,600,270,620],[335,875]),('homes','주거구역',[250,90,630,430],[580,500]),('inns','객잔·다루 거리',[270,610,600,280],[650,865]),('market','상점가',[570,1000,450,390],[820,1195]),('workshops','공방거리',[1170,1260,690,170],[1490,1430]),('martial','무관 구역',[1190,1020,360,200],[1370,1200]),('government','관아 구역',[1610,1000,290,210],[1780,1200]),('plaza','중앙 광장',[970,860,330,180],[1110,1000]),('alliance','무림맹 본단',[930,85,1000,820],[1490,760])]:district(*args)
# City enclosure: no long ornamental tree rows.
row('city_north',240,1945,70)
col('city_west',217,105,1420,gap=(890,1010))
col('city_east',1940,105,1430,gap=(900,1010))
row('city_south',240,1940,1410,gate=(1042,1163))
obj('south_gate','gate',[982,1310,232,172]);landmark('south_entry','남문 · 장사 방면',[1100,1490])
obj('east_gate','gate',[1830,864,220,162])
# Neighbourhoods: room for future residents in yards and at shop sides.
for i,(x,y) in enumerate([(275,115),(600,115),(290,320),(625,325)]):obj(f'home_{i}','home',[x,y,126,113])
obj('residential_well','well',[487,337,43,53]);obj('small_shrine','shrine',[740,130,105,98])
obj('residential_tree','tree',[450,155,70,78]);obj('shrine_tree','tree',[826,305,62,70])
obj('inn_west','inn',[570,620,145,145]);obj('tea_house','inn',[735,650,132,130])
obj('riverside_inn','inn',[285,620,140,143])
for i,(x,y) in enumerate([(255,1015),(340,1130),(270,1270)]):
 obj(f'warehouse_{i}','warehouse',[x,y,132,102]);obj(f'freight_{i}','cargo',[x+110,y+88,39,42])
for i,(x,y) in enumerate([(615,1015),(830,1015),(615,1250),(850,1270)]):obj(f'market_shop_{i}','home',[x,y,126,113])
for i,(x,y) in enumerate([(630,1150),(870,1150),(630,1380),(875,1390)]):obj(f'stall_{i}','stall_a' if i%2 else 'stall_b',[x,y,70,56])
for i,(x,y) in enumerate([(1190,1270),(1430,1275),(1730,1270)]):obj(f'workshop_{i}','workshop',[x,y,136,122])
obj('public_martial_hall','martial_hall',[1190,1020,145,128])
obj('public_martial_annex','home',[1420,1020,95,88])
obj('government_hall','government',[1670,1010,159,142]);obj('government_gate','gate',[1670,1135,155,115])
row('government_front',1600,1900,1225,gate=(1710,1787))
# Alliance occupies a much larger, enclosed compound with three courts.
row('alliance_north',940,1910,85)
col('alliance_west',932,120,880)
col('alliance_east',1905,120,880)
row('alliance_south',940,1910,861,gate=(1414,1548))
obj('alliance_gate','gate',[1330,681,300,222]);landmark('alliance_gate','무림맹 정문',[1480,930])
# Public outer court, lodging and reception on the sides.
obj('reception','government',[1000,620,155,137]);landmark('reception','외원 접수처',[1180,777])
obj('guest_lodging','inn',[1710,620,152,146])
# Rear perimeter framing the two large open training grounds.
obj('west_training_hall','martial_hall',[1010,410,160,143]);obj('east_armory','warehouse',[1690,435,165,120])
obj('west_barracks','home',[1010,220,150,134]);obj('east_barracks','home',[1700,225,150,134])
# Dedicated tall main hall, not a huge stretched ordinary house.
obj('alliance_main_hall','alliance_hall',[1300,105,360,300]);landmark('main_hall','무림맹 회의당',[1480,430])
obj('commander_quarters','government',[1000,105,155,136]);obj('strategist_office','government',[1700,100,155,136])
for i,(x,y) in enumerate([(990,715),(1830,720),(1230,240),(1640,250),(365,790)]):obj(f'courtyard_tree_{i}','tree',[x,y,57,64])
landmark('training','대연무장',[1480,565]);landmark('market','상점가',[780,1215]);landmark('workshops','공방거리',[1500,1400]);landmark('martial','무관 앞뜰',[1370,1170]);landmark('government','관아 앞',[1760,1280]);landmark('harbor','장강 나루',[250,950]);landmark('homes','주거 골목',[535,430]);landmark('inns','객잔 거리',[780,850]);landmark('plaza','중앙 광장',[1100,945])
(out/'layout.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
print(len(d['objects']),'independent objects')
