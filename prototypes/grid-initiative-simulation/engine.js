/* Browser/Node analysis engine. No production game state or save access. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.GridSimulator=api})(globalThis,function(){
'use strict';
const KEYS=['strength','agility','constitution','inner','insight'],DIRS=[[1,0],[0,-1],[-1,0],[0,1]],EPS=1e-7,BEAT=100/30;
const PATTERNS={samjae:['adjacent'],cheongpung:['adjacent',1],yusu:['adjacent',0,1],swaeam:['adjacent',0,0,1],danseok:['fan'],hoepung:['surround'],gwanpung:['line2'],yeonhwan:['line2',1],cheolsan:['adjacent',0,0,1],jingak:['adjacent',0,0,1,true],ungi:['line2',0,0,2],hoeryu:['adjacent'],paak:['fan'],swaerang:['fan'],gwanak:['line2'],banseok:['adjacent',0,0,1],jungun:['line2',0,0,2]};
const clone=x=>JSON.parse(JSON.stringify(x)),snap=x=>Math.round(x*1000)/1000,eq=(a,b)=>a[0]===b[0]&&a[1]===b[1],md=(a,b)=>Math.abs(a[0]-b[0])+Math.abs(a[1]-b[1]),inside=p=>p[0]>=1&&p[0]<=7&&p[1]>=1&&p[1]<=5;
function spatial(id,arts){const s=arts[id];if(id==='basic_defense'||s?.weapon_style==='support')return {shape:'self',pre:0,retreat:0,push:0,follow:false};const p=PATTERNS[id]||['adjacent'];return {shape:p[0],pre:p[1]||0,retreat:p[2]||0,push:p[3]||0,follow:!!p[4]}}
function action(id,stats,weaponId,catalog){
 if(id==='basic_attack')return {id,name:'기본공격',raw:stats.strength+stats.agility+stats.inner,cost:0,guard:0};
 if(id==='basic_defense')return {id,name:'기본방어',raw:0,cost:0,guard:20};
 const s=catalog.arts[id],w=catalog.weapons[weaponId]||{};if(!s)return null;
 const type=w.weapon_type||'none';if(s.required_weapon_type!=null&&s.required_weapon_type!==type)return null;
 const applies=s.required_weapon_type===type&&weaponId!=='none';
 let raw=s.base_damage||0;for(const [key,value]of Object.entries(s.damage_coefficients||{}))raw+=stats[key]*value;
 if(applies)raw*=1+(w.attack_bonus_percent||0)/100;
 const base=s.qi_cost||0,cost=base<=0?base:applies?Math.max(1,Math.ceil(base*(100-(w.qi_reduction_percent||0))/100)):base;
 return {id,name:s.name,raw,cost,guard:s.guard_percent??(s.weapon_style==='sword'?20:0),qi_restore:(s.qi_restore||0)+Math.floor(stats.inner*(s.qi_restore_inner_percent||0)/100),cooldown_turns:s.cooldown_turns||0};
}
function damage(raw,constitution,weaponId,guard,catalog){const passive=catalog.weapons[weaponId]?.damage_reduction_percent||0;return Math.floor(Math.max(0,raw-constitution)*100/(100+constitution)*(1-passive/100)*(1-Math.min(100,Math.max(0,guard))/100)+1e-8)}
function hitFrom(from,to,shape){const dx=Math.abs(to[0]-from[0]),dy=Math.abs(to[1]-from[1]);if(shape==='self')return true;if(shape==='fan'||shape==='surround')return Math.max(dx,dy)===1;if(shape==='line2')return (dx===0||dy===0)&&dx+dy>=1&&dx+dy<=2;return dx+dy===1}
function neighbours(p,other){return DIRS.map(d=>[p[0]+d[0],p[1]+d[1]]).filter(n=>inside(n)&&!eq(n,other))}
function routes(start,target,limit=2){const queue=[{pos:start,path:[]}],seen=new Set([start.join(',')]);for(let n=0;n<queue.length;n++){const v=queue[n];if(v.path.length===limit)continue;for(const p of neighbours(v.pos,target)){const key=p.join(',');if(seen.has(key))continue;seen.add(key);queue.push({pos:p,path:[...v.path,p]})}}return queue}
function attackRoute(start,target,id,arts,limit){const s=spatial(id,arts),options=routes(start,target,limit);for(const r of options){if(hitFrom(r.pos,target,s.shape))return {...r,skillPath:[],hit:true};if(s.pre)for(const p of neighbours(r.pos,target))if(hitFrom(p,target,s.shape))return {pos:p,path:r.path,skillPath:[p],hit:true}}
 let best=options[0];for(const r of options)if(md(r.pos,target)<md(best.pos,target))best=r;return {...best,skillPath:[],hit:false}}
function integer(n,min,max,label){if(!Number.isInteger(n)||n<min||n>max)throw Error(`${label}: ${min}~${max} 사이 정수로 입력하세요.`)}
function validate(input,catalog){if(!input||!Array.isArray(input.actors)||input.actors.length!==2)throw Error('캐릭터 두 명을 설정하세요.');for(const [i,a]of input.actors.entries()){for(const k of KEYS)integer(a.stats?.[k],0,100,`${i+1}번 캐릭터 ${k}`);integer(a.max_hp,1,100000,'체력');integer(a.pos?.[0],1,7,'가로 위치');integer(a.pos?.[1],1,5,'세로 위치');if(!Object.hasOwn(catalog.weapons,a.weapon))throw Error('무기를 선택하세요.');if(!Array.isArray(a.skills)||a.skills.length>4||a.skills.some(id=>id&&!Object.hasOwn(catalog.arts,id)))throw Error('무공은 등록된 것 중 최대4개입니다.');if(a.speed_override!=null)integer(a.speed_override,1,500,'속도 강제값');if(!['attack','third_guard','recover'].includes(a.policy))throw Error('행동 방침이 올바르지 않습니다.')}if(eq(input.actors[0].pos,input.actors[1].pos))throw Error('두 캐릭터의 시작 칸은 달라야 합니다.');if(!['clock','per_action'].includes(input.recovery))throw Error('내기 회복 방식을 확인하세요.');return true}
function choose(a,b,catalog,limit){
 const basic=action('basic_attack',a.stats,a.weapon,catalog),defense=action('basic_defense',a.stats,a.weapon,catalog);
 if(a.policy==='third_guard'&&a.actions%3===0)return {action:defense,route:null};
 const available=[...new Set(a.skills)].filter(Boolean).filter(id=>(a.ready[id]||0)<=a.actions).map(id=>action(id,a.stats,a.weapon,catalog)).filter(s=>s&&s.cost<=a.qi);
 const offensive=available.filter(s=>s.raw>0);const costNeed=Math.max(0,...a.skills.filter(Boolean).map(id=>action(id,a.stats,a.weapon,catalog)?.cost||0));
 const support=available.find(s=>s.qi_restore>0&&a.qi<500&&(a.policy==='recover'?a.qi<Math.min(500,costNeed*2):a.qi<costNeed));
 if(support){const route=attackRoute(a.pos,b.pos,'basic_attack',catalog.arts,limit);return {action:support,route:{...route,skillPath:[]}}}
 const choices=[...offensive,basic].sort((x,y)=>y.raw-x.raw);
 // A zero-damage basic attack remains an attack attempt, not a defensive technique.
 for(const s of choices){const route=attackRoute(a.pos,b.pos,s.id,catalog.arts,limit);if(route.hit)return {action:s,route}}
 const route=attackRoute(a.pos,b.pos,choices[0].id,catalog.arts,limit);return {action:defense,route:{...route,skillPath:[],hit:false}};
}
function snapshot(actors){return actors.map(a=>({name:a.name,hp:a.hp,max_hp:a.max_hp,qi:a.qi,gauge:snap(a.gauge),pos:[...a.pos],guard:a.guard}))}
function run(input,catalog){validate(input,catalog);const config=clone(input),limit=2,maxActions=200;
 const actors=config.actors.map(a=>({...a,name:String(a.name||'무명').slice(0,20),stats:{...a.stats},pos:[...a.pos],hp:a.max_hp,qi:a.stats.inner,speed:a.speed_override??10+a.stats.agility,gauge:0,guard:0,actions:0,attacks:0,skillsUsed:0,basics:0,moved:0,ready:{}}));
 const frames=[{kind:'start',beat:0,actor:-1,action:'시작',damage:0,path:[],state:snapshot(actors)}];let time=0,nextPulse=BEAT,winner=-1,lastTie=1,total=0;
 while(winner<0&&total<maxActions){let dt=Math.min(...actors.map(a=>Math.max(0,(100-a.gauge)/a.speed)));if(config.recovery==='clock')dt=Math.min(dt,Math.max(0,nextPulse-time));time+=dt;for(const a of actors)a.gauge+=a.speed*dt;
  if(config.recovery==='clock'&&time+EPS>=nextPulse){for(const a of actors)a.qi=Math.min(500,a.qi+a.stats.inner);frames.push({kind:'recovery',beat:snap(time/BEAT),actor:-1,action:'공통 박자 · 양쪽 내기 회복',damage:0,path:[],state:snapshot(actors)});nextPulse+=BEAT}
  const ready=actors.map((a,i)=>a.gauge+EPS>=100?i:-1).filter(i=>i>=0);if(!ready.length)continue;let i=ready[0];if(ready.length===2){if(actors[1].stats.agility>actors[0].stats.agility)i=1;else if(actors[0].stats.agility===actors[1].stats.agility){i=1-lastTie;lastTie=i}}
  const a=actors[i],b=actors[1-i];a.gauge=Math.max(0,a.gauge-100);a.actions++;total++;
  const decision=choose(a,b,catalog,limit),s=decision.action,sp=spatial(s.id,catalog.arts);const basePath=decision.route?.path||[],prePath=decision.route?.skillPath||[],postPath=[],pushed=[];
  for(const p of [...basePath,...prePath])a.pos=[...p];a.moved+=basePath.length+prePath.length;a.qi-=s.cost;let hit=0;
  if(s.id!=='basic_defense'&&sp.shape!=='self'){
   hit=damage(s.raw,b.stats.constitution,b.weapon,b.guard,catalog);b.hp=Math.max(0,b.hp-hit);a.attacks++;if(s.id==='basic_attack')a.basics++;else a.skillsUsed++;
   if(b.hp>0&&sp.push){const d=[Math.sign(b.pos[0]-a.pos[0]),Math.sign(b.pos[1]-a.pos[1])],old=[...b.pos];for(let n=0;n<sp.push;n++){const p=[b.pos[0]+d[0],b.pos[1]+d[1]];if(!inside(p)||eq(p,a.pos))break;b.pos=p;pushed.push([...p])}if(sp.follow&&pushed.length){a.pos=old;postPath.push([...old]);a.moved++}}
   if(sp.retreat){const p=[a.pos[0]+Math.sign(a.pos[0]-b.pos[0]),a.pos[1]+Math.sign(a.pos[1]-b.pos[1])];if(inside(p)&&!eq(p,b.pos)){a.pos=p;postPath.push([...p]);a.moved++}}
  }
  const restored=Math.min(s.qi_restore||0,500-a.qi);a.qi+=restored;if(s.cooldown_turns)a.ready[s.id]=a.actions+s.cooldown_turns+1;
  a.guard=Math.max(a.guard,s.guard||0);b.guard=0;if(config.recovery==='per_action')a.qi=Math.min(500,a.qi+a.stats.inner);
  frames.push({kind:'action',beat:snap(time/BEAT),actor:i,action:s.name,id:s.id,damage:hit,raw:s.raw,cost:s.cost,restored,path:[...basePath,...prePath,...postPath],basePath,skillPath:[...prePath,...postPath],pushed,state:snapshot(actors)});if(b.hp<=0)winner=i;
 }
 return {config,frames,winner,draw:winner<0,beats:snap(time/BEAT),player_hp:actors[0].hp,player_actions:actors[0].actions,enemy_actions:actors[1].actions,player_attacks:actors[0].attacks,enemy_attacks:actors[1].attacks,player_skills:actors[0].skillsUsed,player_basics:actors[0].basics,player_moved:actors[0].moved,stats:actors[0].stats,summary:actors.map(a=>({actions:a.actions,attacks:a.attacks,skills:a.skillsUsed,basics:a.basics,hp:a.hp}))};
}
function fromFixture(c,data){return {recovery:c.recovery,actors:[{name:'도원',stats:clone(c.stats),max_hp:300,pos:[...c.layout.player],weapon:data.player_weapon,skills:[data.player_art,'basic_attack','basic_defense',''],policy:'attack',speed_override:c.control?24:null},{name:data.source_enemy.name,stats:clone(data.source_enemy.stats),max_hp:data.source_enemy.max_hp*c.hp_scale,pos:[...c.layout.enemy],weapon:data.source_enemy.weapon,skills:[...data.source_enemy.skills,'basic_attack','basic_defense'].slice(0,4),policy:'third_guard',speed_override:null}]}}
return {run,action,damage,spatial,validate,fromFixture,KEYS};
});
