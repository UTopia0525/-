"""Build deterministic presentation-only cues; never edits dialogue text, outcomes or rewards."""
import collections,json,pathlib,re
ROOT=pathlib.Path(__file__).resolve().parents[1]
lines={}
def collect(value):
 if isinstance(value,list):
  if len(value)>1 and isinstance(value[0],str) and isinstance(value[1],str) and re.fullmatch(r'[a-z_0-9]+',value[0]) and re.search('[가-힣]',value[1]):lines[value[0]+'|'+value[1]]=(value[0],value[1])
  for child in value:collect(child)
 elif isinstance(value,dict):
  for child in value.values():collect(child)
for path in (ROOT/'godot/data').glob('*.json'):
 if path.name in ['dialogue_expression_cues.json','portrait_expressions.json']:continue
 collect(json.loads(path.read_text()))
# Literal lines in controllers use the same actor|text key as JSON scripts.
for path in (ROOT/'godot/scripts').glob('*.gd'):
 for actor,text in re.findall(r'\[\s*"([a-z_0-9]+)"\s*,\s*"([^"\n]+)"',path.read_text()):
  if re.search('[가-힣]',text):lines[actor+'|'+text]=(actor,text)
SAD=['미안하','미안해','미안하오','미안합니다','죄송','후회','죄책','돌아오지 못','돌아오지 않','못 찾았','찾지 못했','잃었','잃은','잃고','죽었','죽은','죽음','목숨을 잃','떠난 건가','빈 쌀독','괴롭','눈물','울음','걱정하는 것도 벅', '못 보내면', '얼굴을 못 봐','굶','그 빚','남은 것이 없','더는 없소','다른 쪽으로 간','그 사람은 집에','씻기는 것은','돈을 놓고','덜 실패한','배가 가라앉','표두님도','제 첫 표행도','이름을 걸고 표물을','그들의 두려움','기다리던 사람','무거워서','허리를 다친','크윽','기침','늙은 부모도 모두 여기','아깝지 않은','얼굴을 떠올리고 싶지는','손끝이 떨리','나한테도 같은','협객이라 불리고','책임질 수 있을지','일이 끝났다고 여겼','공명심','찾을 수 없','팔이……','그때까지 버틸까']
ANGRY=['네놈','이놈','놈들','내놓아라','무릎을 꿇','침입자','가만두지','무사할 줄','잊지는 않겠다','손대지 마','손부터 거두','말로 끝낼 기회','뿌린 돈','그 손을 놓','목숨이 아깝','갈취','강탈','사람 먹을 것까지','사람을 굶기','내 손으로 벤','빼앗기기 싫','이런 짓','누가 이런','속이지 마','물러선 사람에게까지','수작','그만두세요','치워라','입을 다물','칼을 거두세요']
SURPRISE=['흑린채입니다','물이 찹니다','밑창이 벌어','저쪽 난간이','손 놓지 마십시오','발이, 밧줄','여기…… 여기 있네','누구냐!','정말……','정말로','붙잡혀 있다는','문주가','문주라','하오문을 맡고','저희 문도라면','육소전을 아시오','정말 돌아왔','어르신?','귀물은?','……표두도?','그럼 표국은','알고 계셨','어떻게 아','이게 무슨','무슨 일이','어찌 된','어찌하여','설마','뜻밖','놀랐','깜짝','이럴 수가']
SMILE=['고맙','감사','다행','반갑','반가워','어서 오','잘 왔','돌아왔으면 됐다','그걸로 됐','안심','잘했다','좋다.','수고했','수고하셨','웃음','하하','허허','후후','편히 쉬','다시 오셨','다음에 주십시오','이번엔 끝까지','딸애가 싸 준','먼저 웃','잘 지내','잘되었','잘 되었','앞길에 도움','차 한 잔 드릴','밥부터 챙겨','신세도 지고','끝나면 한잔','누구나 하나씩','밥맛이 좋은','함께 갑시다','조금씩 모았소']
# Dramatic scenes receive explicit wording-based overrides ahead of broad cues.
OVERRIDES={
 'cy_eunsowol|그들이 감당할 몫을 방주께서 대신 걱정하실 필요는 없겠지요. 합의한 내역부터 확인하시지요.':'neutral',
 'qy_ren_shoutian|돌아왔으면 됐다. 다친 데는 없느냐?':'smile',
 'warehouse_keeper|글씨를 알아볼 수 있으니 됐어. 사람이 안 다친 것이 먼저고.':'smile',
 'young_craftsman|아버지가 덜 걱정하셨다면 다행입니다. 그렇다고 계속 남에게 안부만 부탁할 수는 없겠지요.':'smile',
 'hero|저 사람에게는 그렇게 말할 수 있었다.':'sad',
 'hero|살아 있다. 그걸로 됐다고 생각했는데.':'sad',
 'hero|함이 떠내려간 쪽을 자꾸 보게 된다.':'sad',
 'hero|내가 늦은 게 아니다.':'sad',
 'hero|다른 쪽으로 간 거다.':'sad',
 'hero|표물도 사람도 지킬 수 있다고, 그렇게 믿고 싶다.':'sad',
 'hero|하지만 지금도…… 둘 다 멀어지고 있다.':'sad',
 'hero|간수 하나를 쓰러뜨리고, 고맙다는 말을 듣고…… 일이 끝났다고 여겼다.':'sad',
 'hero|끝난 것은 내가 할 일이었나. 아니면 내가 하고 싶었던 일이었나.':'sad',
 'hero|이곳에 남을 생각도 없으면서, 내 칼이면 충분하다고 믿었구나.':'sad',
 'hero|그대의 이름이 남의 팔을 붙잡을 허락까지 주지는 않을 텐데.':'angry',
 'cy_eunsowol|그 이름을 빌려 손님을 겁주고 예인을 붙잡은 사정까지, 방주께 소상히 전해 드릴까요?':'angry',
 'cy_eunsowol|저는 하오문을 맡고 있어요. 이 이야기는 소협께만 드리는 겁니다. 밖에서는 지금처럼 은 누주면 충분해요.':'neutral',
 'qy_liang_boan|소협은 내일도 여기 있을 거요?':'sad',
 'qy_liang_boan|……그랬으면 좋겠네.':'sad',
 'hero|함은 저쪽 물살을 타고 있다. 저 사람에게 갔다 돌아올 수는 없다.':'sad',
 'hero|그 대답만큼은 어렵지 않았다. 지켰느냐고 물었으니까.':'sad',
 'sailor|그래. 다음에. ……다음이 있다는 게, 참 이상하군.':'sad',
 'hero|……살아 돌아가셔야지요. 기다리는 분도 있으실 테니.':'sad',
 'hero|이 돈이…… 전부입니까?':'sad',
 'hero|그 돈을 기다리던 사람들도 있겠지요.':'sad',
}
def mood(actor,text):
 key=actor+'|'+text
 if key in OVERRIDES:return OVERRIDES[key]
 # Do not smile merely because a line quotes somebody else's gratitude.
 if any(word in text for word in ANGRY):return 'angry'
 if any(word in text for word in SURPRISE):return 'surprised'
 if any(word in text for word in SAD):return 'sad'
 if any(word in text for word in SMILE):return 'smile'
 return 'neutral'
cues={key:mood(a,t) for key,(a,t) in sorted(lines.items())}
# Save only intentional departures; unlisted lines and old saves resolve neutral.
cues={k:v for k,v in cues.items() if v!='neutral'}
path=ROOT/'godot/data/dialogue_expression_cues.json'
path.write_text(json.dumps({'version':1,'default':'neutral','note':'Presentation-only actor|exact text lookup; explicit per-line emotion/emotions override. No live keyword inference.','lines':cues},ensure_ascii=False,indent=2)+'\n')
portraits={}
for p in sorted((ROOT/'godot/assets/portraits').rglob('*.png')):
 if p.parent.name=='expressions' or p.name=='constable.png':continue
 rel=str(p.relative_to(ROOT/'godot'))
 portraits['res://'+rel]={'sheet':'res://assets/portraits/expressions/'+str(p.relative_to(ROOT/'godot/assets/portraits')).replace('/','--'),'grid':[2,2],'order':['smile','angry','sad','surprised']}
(ROOT/'godot/data/portrait_expressions.json').write_text(json.dumps({'version':1,'neutral':'original','portraits':portraits},ensure_ascii=False,indent=2)+'\n')
print('Illustrated identities:',len(portraits),'dialogue lines scanned:',len(lines),'non-neutral cues:',len(cues),dict(collections.Counter(cues.values())))
