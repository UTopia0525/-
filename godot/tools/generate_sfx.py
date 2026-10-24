import math,wave,struct,random
from pathlib import Path
rate=22050;rng=random.Random(731)
for name,duration in [('confirm',.13),('coin',.30),('quest',.45),('learn',.45),('hit',.16),('block',.20),('attack_sword',.24),('attack_saber',.30),('attack_spear',.22),('attack_none',.18)]:
 samples=[];filtered=0.0
 for i in range(int(rate*duration)):
  t=i/rate;env=min(1,t/.006)*math.exp(-t/(duration*.25));v=0
  if name=='confirm':v=math.sin(2*math.pi*660*t)*.25
  elif name=='coin':v=(math.sin(2*math.pi*1174*t)+.5*math.sin(2*math.pi*1761*t))*.22
  elif name in ['quest','learn']:
   notes=[523,659,784] if name=='quest' else [440,587,880];index=min(2,int(t/(duration/3)));phase=t-index*(duration/3);v=.32*math.sin(2*math.pi*notes[index]*phase)*math.exp(-phase*15);env=min(1,t/.005)
  elif name.startswith('attack_'):
   # Swept filtered noise: steel slices, heavier saber, sharp thrust, soft fist.
   low={'attack_sword':.18,'attack_saber':.48,'attack_spear':.08,'attack_none':.75}[name]
   noise=rng.uniform(-1,1);previous=filtered
   filtered=low*previous+(1-low)*noise
   env=math.sin(math.pi*t/duration)**1.8
   v=.46*filtered+.07*math.sin(2*math.pi*(360-700*t)*t)
  elif name=='hit':v=.35*(rng.uniform(-1,1)*.7+math.sin(2*math.pi*(130-200*t)*t)*.5)
  else:v=.2*(math.sin(2*math.pi*880*t)+math.sin(2*math.pi*1369*t)+rng.uniform(-.25,.25))
  samples.append(struct.pack('<h',int(max(-1,min(1,v*env))*32767)))
 with wave.open('godot/assets/sfx/'+name+'.wav','wb') as out:out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate);out.writeframes(b''.join(samples))
