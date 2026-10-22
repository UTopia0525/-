(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  const canvas = $('world');
  let ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = false;
  const W = 960, H = 540, GRID = 20;
  const CONFIG = Object.freeze({
    player: Object.freeze({ strength: 10, agility: 10, constitution: 10, inner: 10, insight: 10, hp: 300 }),
    enemy: Object.freeze({ constitution: 5, hp: 150, rawDamage: 40 }),
    // DEMO ONLY: rounding, first move, hit certainty and enemy attack are provisional.
    hitDelay: 650, returnDelay: 850
  });
  const damage = (raw, constitution) => Math.floor(Math.max(0, raw - constitution) * 100 / (100 + constitution));
  const actorTypes = {
    hero: { coat: '#526c7e', trim: '#a5b4b2', hair: '#202525', pants: '#263b44', skin: '#d2ac80' },
    captain: { coat: '#5d6150', trim: '#a69971', hair: '#333730', pants: '#303d36', skin: '#c29c72', beard: true },
    apothecary: { coat: '#a1685c', trim: '#d2bfa0', hair: '#312f2a', pants: '#5c5042', skin: '#d8b18c', bun: true },
    sailor: { coat: '#727b74', trim: '#c1b38b', hair: '#30382d', pants: '#3e4c41', skin: '#c39c72' },
    clerk: { coat: '#83846a', trim: '#c5c0a1', hair: '#34362e', pants: '#3d4b3f', skin: '#d3b491' },
    pirate: { coat: '#6a5142', trim: '#af7358', hair: '#3b3027', pants: '#30392f', skin: '#c49b71', beard: true }
  };
  const state = {
    phase: 'title', scene: 'dock', started: false, talkedCaptain: false,
    x: 310, y: 410, facing: 'down', moving: false, path: [], keys: new Set(),
    dialogue: null, nearest: null, selected: false, busy: false,
    playerHP: CONFIG.player.hp, enemyHP: CONFIG.enemy.hp, turn: 1, epoch: 0,
    lastTime: 0, footTime: 0, script: ''
  };
  let frameTime = 0;
  const dockAreas = [[20, 240, 515, 280], [510, 265, 190, 70], [680, 155, 245, 290]];
  const dockObstacles = [[80, 220, 130, 65], [350, 255, 70, 60], [50, 430, 95, 65], [390, 440, 60, 50], [795, 155, 115, 95], [752, 350, 55, 45]];
  const deckAreas = [[155, 125, 645, 325]];
  const deckObstacles = [[175, 145, 90, 65], [650, 340, 100, 65], [470, 165, 28, 55], [190, 355, 65, 55]];
  const dockActors = [
    { id: 'captain', name: '서문길', type: 'captain', x: 485, y: 350, label: '표두', action: '대화하기' },
    { id: 'apothecary', name: '진소옥', type: 'apothecary', x: 150, y: 325, label: '약방 일꾼', action: '대화하기' },
    { id: 'sailor', name: '허만복', type: 'sailor', x: 495, y: 455, label: '선원', action: '대화하기' },
    { id: 'clerk', name: '육승', type: 'clerk', x: 315, y: 260, label: '상단 서기', action: '대화하기' },
    { id: 'boarding', name: '호송선', type: null, x: 620, y: 300, label: '승선', action: '승선하기' }
  ];
  const deckActors = [
    { id: 'deck-captain', name: '서문길', type: 'captain', x: 650, y: 235, label: '표두', action: '보고하기' },
    { id: 'deck-sailor', name: '허만복', type: 'sailor', x: 310, y: 195, label: '선원', action: '대화하기' }
  ];
  function actors() { return state.scene === 'dock' ? dockActors : deckActors; }
  function rect(x, y, w, h, color) { ctx.fillStyle = color; ctx.fillRect(Math.round(x), Math.round(y), Math.round(w), Math.round(h)); }
  function poly(points, color) { ctx.fillStyle = color; ctx.beginPath(); points.forEach(([x,y],i) => i ? ctx.lineTo(x,y) : ctx.moveTo(x,y)); ctx.closePath(); ctx.fill(); }
  function hash(x, y) { const n = Math.sin(x * 127.1 + y * 311.7) * 43758.5453; return n - Math.floor(n); }
  function label(text, x, y, color = '#eee1bb', size = 11) {
    ctx.font = `${size}px system-ui, sans-serif`; ctx.textAlign = 'center'; ctx.fillStyle = '#17241edb';
    const width = ctx.measureText(text).width + 12;
    ctx.fillRect(Math.round(x-width/2), y-size-3, width, size+8);
    ctx.fillStyle = color; ctx.fillText(text, x, y);
  }
  function water(t) {
    rect(0,0,W,H,'#345859');
    const colors = ['#42686a', '#3a6262', '#4b7070', '#305657'];
    for (let y=0;y<H;y+=16) for(let x=0;x<W;x+=32) {
      const n=hash(x,y); if(n>.4){const shift=Math.floor(Math.sin(t*.0007+y*.04)*4);rect(x+shift,y,8+n*18,2,colors[Math.floor(n*4)]);}
      if(n>.88) rect(x+9,y+7,7,1,'#81978a');
    }
    // Small drifting leaf, purely decorative.
    rect((t*.006+650)%W,72,8,3,'#a2aa69');
  }
  function stoneGround(x,y,w,h) {
    rect(x,y,w,h,'#888c75');
    for(let row=0;row<Math.ceil(h/26);row++) for(let col=0;col<Math.ceil(w/38)+1;col++){
      const px=x+col*38-(row%2)*19,py=y+row*26,n=hash(col,row);
      if(px>=x && px+36<=x+w) {
        rect(px+1,py+1,35,23,['#969981','#a2a18a','#8f927d','#aaa58b'][Math.floor(n*4)]);
        rect(px+3,py+2,29,1,'#b4af95');
        if(n>.65) rect(px+10,py+17,12,2,'#7a846c');
      }
    }
  }
  function planks(x,y,w,h,vertical=false) {
    rect(x,y,w,h,'#6f593e');
    if(vertical){for(let xx=x;xx<x+w;xx+=19){const n=hash(xx,y);rect(xx+1,y,17,h,n>.5?'#a28858':'#9a7b50');rect(xx+2,y+5,1,h-10,'#bca06d');for(let yy=y+30;yy<y+h;yy+=76){rect(xx+2,yy,14,2,'#655335');rect(xx+4,yy+5,2,2,'#4f4b32');}}}
    else{for(let yy=y;yy<y+h;yy+=18){const n=hash(x,yy);rect(x,yy+1,w,16,n>.5?'#a78a59':'#987d50');rect(x+3,yy+2,w-6,1,'#bea06c');for(let xx=x+35+(Math.floor(yy/18)%2)*45;xx<x+w-5;xx+=90){rect(xx,yy+2,2,13,'#6a583c');rect(xx+5,yy+6,2,2,'#5e5338');}}}
  }
  function crate(x,y,w=36,h=32) {
    rect(x+4,y+5,w,h,'#273e333f');rect(x,y,w,h,'#685438');rect(x+3,y+3,w-6,h-6,'#a68b58');
    rect(x+3,y+3,w-6,3,'#c2a372');rect(x+3,y+h-7,w-6,3,'#78613f');rect(x+5,y+5,4,h-10,'#78613f');rect(x+w-9,y+5,4,h-10,'#78613f');
    for(let i=0;i<w-10;i+=7)rect(x+7+i,y+10,2,h-20,'#8c7148');
    rect(x+w/2-2,y+4,4,h-8,'#bfab77');
  }
  function sack(x,y) { rect(x+3,y+6,23,24,'#b6a379');rect(x+6,y+2,16,6,'#d0b789');rect(x+1,y+12,27,13,'#b9a274');rect(x+6,y+7,3,18,'#d2bc8d');rect(x+19,y+9,3,15,'#9a8864');rect(x+10,y+1,10,3,'#776444'); }
  function post(x,y) { rect(x+3,y+3,11,19,'#2b3b3066');rect(x,y,13,18,'#654e36');rect(x+2,y,4,16,'#aa8757');rect(x-1,y-4,15,7,'#b69a67');rect(x+2,y-3,10,2,'#d5b682'); }
  function rope(x,y,scale=1) { ctx.strokeStyle='#c1ad7b';ctx.lineWidth=3;ctx.beginPath();ctx.ellipse(x,y,16*scale,7*scale,0,0,Math.PI*2);ctx.stroke();ctx.beginPath();ctx.ellipse(x+1,y,11*scale,4*scale,0,0,Math.PI*2);ctx.stroke(); }
  function warehouse() {
    rect(0,114,229,126,'#2b3e3255');rect(8,117,203,108,'#c4c1a1');rect(18,143,185,76,'#ddd0ad');
    rect(32,165,48,54,'#3d4233');rect(38,171,37,48,'#655b42');rect(58,176,3,43,'#9b855b');
    rect(114,161,64,37,'#6e6c50');for(let x=120;x<175;x+=9)rect(x,164,3,30,'#b8ad82');
    poly([[0,72],[193,72],[228,136],[0,136]],'#3c4941');
    for(let y=76;y<134;y+=9){for(let x=0;x<210;x+=15){rect(x+(y%2)*5,y,12,5,'#65746a');rect(x+(y%2)*5,y+5,12,2,'#293d35');}}
    rect(0,134,229,5,'#263b30');rect(12,139,8,88,'#635b43');rect(199,139,8,88,'#635b43');
    // Small medicine stall.
    rect(80,221,130,6,'#524e39');rect(86,226,5,57,'#63553c');rect(199,226,5,57,'#63553c');
    for(let i=0;i<13;i++)rect(80+i*10,209,10,19,i%2?'#8c9b7d':'#b3b18e');
    rect(83,268,124,10,'#9d8154');rect(90,278,6,15,'#6f5d3f');rect(194,278,6,15,'#6f5d3f');
    for(let i=0;i<5;i++){rect(101+i*18,254,10,13,['#c4c4ab','#8d9b83','#bbab87'][i%3]);rect(104+i*18,251,5,4,'#5a6249');}
    rect(187,150,25,45,'#cbbb8e');ctx.fillStyle='#555e44';ctx.textAlign='center';ctx.font='16px serif';ctx.fillText('藥',199,179);
  }
  function willow(x,y) {
    rect(x,y,12,95,'#665e43');rect(x+4,y+5,5,85,'#8a7b52');
    for(let i=0;i<17;i++){const xx=x-50+(i*19)%105,yy=y-25+Math.floor(i/6)*16;rect(xx,yy,35,17,i%2?'#6a8052':'#7d8c5c');for(let j=0;j<3;j++){const len=35+hash(i,j)*65;rect(xx+j*11,yy+12,3,len,'#82925c');rect(xx+j*11+3,yy+20,2,len-15,'#657f4f');}}
  }
  function drawDock(t) {
    water(t);stoneGround(0,180,535,360);rect(535,183,13,357,'#52614a');
    for(let y=185;y<540;y+=28){rect(535,y,13,22,'#9b9a78');rect(535,y+22,13,3,'#344e43');}
    // Cargo boat and broad navigable gangplank.
    poly([[646,166],[694,118],[928,125],[954,168],[949,436],[914,474],[688,468],[646,429]],'#283e35');
    poly([[655,163],[694,130],[922,136],[941,169],[938,431],[911,459],[694,454],[659,426]],'#6b553a');
    planks(677,151,254,291,true);
    rect(667,157,9,277,'#c0a16a');rect(931,157,9,277,'#c0a16a');rect(681,439,244,9,'#ae8b53');
    for(let y=160;y<435;y+=53){post(662,y);post(928,y);}
    rect(795,155,115,89,'#81704f');rect(804,168,96,71,'#9c875c');rect(816,180,31,58,'#3e4937');rect(858,179,30,24,'#4a5140');for(let x=861;x<887;x+=7)rect(x,180,2,23,'#a59870');
    poly([[785,150],[898,142],[922,163],[796,170]],'#49584c');for(let x=792;x<908;x+=14)rect(x,153,10,4,'#6d7a65');
    rect(839,82,12,66,'#706346');rect(844,88,4,60,'#bc9d65');poly([[850,86],[900,110],[850,111]],'#a17c57');
    planks(515,268,175,63);rect(515,267,175,5,'#c3ae7c');rect(515,329,175,4,'#776441');
    post(518,252);post(518,339);post(675,252);post(675,339);
    warehouse();willow(264,125);
    crate(350,255,42,38);crate(392,274,28,40);crate(361,241,31,24);
    crate(50,445,42,39);sack(97,450);sack(115,460);crate(390,451,44,30);
    crate(752,350,42,34);rope(815,392);sack(863,303);sack(888,311);
    rope(504,418);post(527,461);post(527,210);post(527,510);
    rect(302,219,5,32,'#665a3d');rect(292,217,30,20,'#c1b58b');rect(298,221,19,2,'#7e7958');rect(298,226,16,2,'#7e7958');
    label('청류진 나루',367,174,'#ded9b5',12);label('승선',618,283,'#f0d59a',10);
    // Small flowers in cracks, decorative and deterministic.
    for(let i=0;i<28;i++){const x=18+hash(i,7)*490,y=302+hash(i,9)*225; if(hash(i,5)>.55){rect(x,y,3,6,'#688057');rect(x+3,y+2,4,2,'#81935c');}}
  }
  function drawDeck(t) {
    water(t);poly([[124,122],[260,63],[738,63],[838,120],[838,458],[772,497],[190,497],[124,458]],'#2c3d32');
    poly([[137,130],[264,79],[732,79],[823,130],[823,450],[767,481],[192,481],[137,450]],'#70583c');
    planks(154,123,648,329);rect(147,126,8,329,'#c5a36a');rect(803,126,8,329,'#c5a36a');rect(166,452,629,9,'#bd9c65');
    for(let x=163;x<802;x+=69){post(x,110);post(x,449);}for(let y=164;y<450;y+=68){post(137,y);post(807,y);}
    rect(165,106,634,5,'#a89060');rect(167,442,634,4,'#9c8053');
    crate(175,145,45,43);crate(220,155,44,46);sack(187,145);crate(650,350,45,43);crate(700,348,44,45);crate(190,366,49,35);
    rect(470,164,28,55,'#716044');rect(476,160,16,56,'#b4935f');rect(481,53,8,124,'#957c50');rect(478,110,15,5,'#5f5139');
    poly([[490,58],[615,76],[608,136],[490,128]],'#c1b391');rect(490,61,120,3,'#d6c9a2');
    rope(551,202);rope(728,294);sack(739,169);sack(763,183);
    // An approaching small skiff visible beyond the rail.
    const bob=Math.round(Math.sin(t*.002)*2);
    poly([[855,207+bob],[915,210+bob],[924,232+bob],[851,230+bob]],'#725b3d');rect(861,214+bob,47,9,'#ad8c58');
  }
  function drawSprite(target, x, y, type, scale=2, facing='down', step=0, shadow=true) {
    const p=actorTypes[type] || actorTypes.hero;
    const r=(xx,yy,w,h,c)=>{target.fillStyle=c;target.fillRect(Math.round(x+(xx-8)*scale),Math.round(y+(yy-25)*scale),w*scale,h*scale);};
    if(shadow){target.fillStyle='#14241e66';target.beginPath();target.ellipse(x,y,11*scale,3*scale,0,0,Math.PI*2);target.fill();}
    const swing=Math.sin(step)*1.5;
    r(3,21+swing,4,5,p.pants);r(9,21-swing,4,5,p.pants);r(2,25+swing,5,2,'#26332c');r(9,25-swing,5,2,'#26332c');
    r(2,11,12,13,p.coat);r(0,12,3,8,p.coat);r(13,12,3,8,p.coat);r(0,19,3,3,p.skin);r(13,19,3,3,p.skin);
    r(3,12,2,9,p.trim);r(7,12,2,8,p.trim);r(2,20,12,2,'#5a5140');r(7,20,3,2,'#c1aa71');
    r(3,3,10,9,p.skin);r(2,2,12,5,p.hair);r(4,0,8,3,p.hair);r(6,-2,5,3,p.hair);
    if(facing==='up'){r(3,3,10,7,p.hair);r(5,8,6,4,p.hair);}else{r(3,5,2,3,p.hair);r(11,5,2,3,p.hair);r(5,7,1,1,'#292d25');r(10,7,1,1,'#292d25');r(7,10,3,1,'#a87958');if(p.beard)r(5,10,6,3,p.hair);}
    if(type==='pirate'){r(2,3,12,2,'#ab6650');r(13,4,3,5,'#a26049');r(16,10,2,13,'#c7c9a5');r(15,21,4,2,'#9e8754');}
    if(type==='hero'){r(13,14,2,13,'#c8c8ad');r(12,15,4,2,'#b8a16a');}
    if(type==='clerk'){r(0,14,5,7,'#d6cbaa');r(1,15,3,1,'#8c8a62');}
  }
  const sceneryCache = new Map();
  function drawScene(t) {
    if (!sceneryCache.has(state.scene)) {
      const image = document.createElement('canvas'); image.width=W; image.height=H;
      const mainContext=ctx; ctx=image.getContext('2d');
      if(state.scene==='dock')drawDock(0);else drawDeck(0);
      ctx=mainContext; sceneryCache.set(state.scene,image);
    }
    ctx.drawImage(sceneryCache.get(state.scene),0,0);
    // Static tile scenery is cached; only sprites and a few ripples animate.
    for(let i=0;i<7;i++) {
      const x=360+i*74+Math.round(Math.sin(t*.001+i)*9);
      rect(x,28+(i%3)*19,12,1,'#88a79866');
    }
    const all=actors().filter(a=>a.type).concat([{x:state.x,y:state.y,type:'hero',player:true}]).sort((a,b)=>a.y-b.y);
    for(const a of all)drawSprite(ctx,a.x,a.y,a.type,2,a.player?state.facing:'down',a.player&&state.moving?state.footTime:0);
    for(const a of actors()){
      if(a.type && (Math.hypot(a.x-state.x,a.y-state.y)<120 || (a.id.includes('captain') && !state.dialogue)))label(a.name,a.x,a.y-66,'#e2d9b4',10);
      if((a.id==='captain'&&!state.talkedCaptain)||(a.id==='boarding'&&state.talkedCaptain)||(a.id==='deck-captain')){
        const yy=a.y-80+Math.round(Math.sin(t*.003)*3);poly([[a.x,yy+8],[a.x-5,yy],[a.x+5,yy]],'#e0c47f');
      }
    }
    if(state.path.length){const p=state.path[state.path.length-1];ctx.strokeStyle='#e2d28b';ctx.lineWidth=2;ctx.strokeRect(p.x-5,p.y-3,10,6);}
    const grad=ctx.createRadialGradient(480,270,200,480,270,620);grad.addColorStop(0,'#00000000');grad.addColorStop(1,'#12251a50');ctx.fillStyle=grad;ctx.fillRect(0,0,W,H);
  }
  function contains(area,x,y,pad=0){return x>=area[0]+pad&&x<=area[0]+area[2]-pad&&y>=area[1]+pad&&y<=area[1]+area[3]-pad;}
  function walkable(x,y){const areas=state.scene==='dock'?dockAreas:deckAreas;const obstacles=state.scene==='dock'?dockObstacles:deckObstacles;return areas.some(r=>contains(r,x,y,5))&&!obstacles.some(r=>contains([r[0]-6,r[1]-3,r[2]+12,r[3]+9],x,y));}
  function pathTo(x,y){
    const cols=W/GRID,rows=H/GRID,start=[Math.floor(state.x/GRID),Math.floor(state.y/GRID)],goal=[Math.floor(x/GRID),Math.floor(y/GRID)];
    const key=(a,b)=>b*cols+a, origin=key(...start), dest=key(...goal);
    if(!walkable(goal[0]*GRID+GRID/2,goal[1]*GRID+GRID/2))return;
    const queue=[start],prev=new Map([[origin,null]]);let pos=0;
    while(pos<queue.length){const [cx,cy]=queue[pos++];if(key(cx,cy)===dest)break;for(const [dx,dy]of[[1,0],[-1,0],[0,1],[0,-1]]){const nx=cx+dx,ny=cy+dy,nk=key(nx,ny);if(nx<0||ny<0||nx>=cols||ny>=rows||prev.has(nk)||!walkable(nx*GRID+10,ny*GRID+10))continue;prev.set(nk,key(cx,cy));queue.push([nx,ny]);}}
    if(!prev.has(dest))return;
    const path=[];let k=dest;while(k!==origin){path.push({x:(k%cols)*GRID+10,y:Math.floor(k/cols)*GRID+10});k=prev.get(k);}
    state.path=path.reverse();
  }
  function announce(text){$('announcement').textContent=text;}
  function log(text){$('event-log').textContent=text;announce(text);}
  function objective(text,step){$('objective').textContent=text;document.querySelectorAll('#journey li').forEach(el=>{const n=Number(el.dataset.step);el.classList.toggle('active',n===step);el.classList.toggle('done',n<step);});}
  function setLocation(text){$('location-label').textContent=text;}
  function clearMovement(){state.path=[];state.keys.clear();state.moving=false;}
  function portrait(type){const p=$('portrait').getContext('2d');p.clearRect(0,0,48,56);drawSprite(p,24,52,type||'captain',2.8,'down',0,false);}
  function say(lines,onDone){
    clearMovement();state.dialogue={lines,index:0,onDone};$('interaction').hidden=true;$('dialogue').hidden=false;showLine();
  }
  function showLine(){const d=state.dialogue;if(!d)return;const line=d.lines[d.index];$('speaker').textContent=line[0];$('dialogue-text').textContent=line[1];portrait(line[2]);$('next-dialogue').innerHTML=d.index===d.lines.length-1?'계속 <span>▾</span>':'다음 <span>▾</span>';announce(`${line[0]}. ${line[1]}`);}
  function nextLine(){const d=state.dialogue;if(!d)return;if(++d.index<d.lines.length)showLine();else{state.dialogue=null;$('dialogue').hidden=true;const fn=d.onDone;if(fn)fn();canvas.focus({preventScroll:true});}}
  async function transition(text,fn){const epoch=state.epoch;state.phase='transition';clearMovement();$('interaction').hidden=true;$('transition').textContent=text;$('transition').hidden=false;await wait(650);if(epoch!==state.epoch)return;fn();$('transition').hidden=true;}
  function wait(ms){return new Promise(resolve=>setTimeout(resolve,ms));}
  function interact(){
    if(state.dialogue){nextLine();return;}
    if(state.phase!=='explore')return;
    const actor=state.nearest;if(!actor){log('사람이나 승선 지점 가까이에서 E를 눌러보세요.');return;}
    if(actor.id==='captain')say([
      ['서문길','오늘부터 너도 정식으로 표행에 나서는 거다. 긴장했느냐?','captain'],
      ['서문길','저 배에 우리 표국의 식구들이 함께 탄다. 화물을 살피되, 동료가 어디 있는지도 잊지 마라.','captain'],
      ['서문길','준비가 되면 오른쪽 널빤지를 건너 배에 올라라. 갑판에서 다시 보자.','captain']
    ],()=>{state.talkedCaptain=true;objective('오른쪽 승선 지점으로 이동해 배에 오르세요.',1);log('표두와 인사를 나눴습니다. 호송선이 기다립니다.');});
    else if(actor.id==='apothecary')say([
      ['진소옥','그 상자는 약재예요. 쌀가마처럼 던졌다가는 제가 먼저 화낼 거예요.','apothecary'],
      ['진소옥','이번에는 늦지 않게 도착했으면 좋겠네요. 기다리는 사람들이 있거든요.','apothecary']
    ]);
    else if(actor.id==='sailor')say([
      ['허만복','첫 표행이라고? 어깨 힘 좀 빼게. 그렇게 굳어 있으면 배가 흔들릴 때 바로 넘어진다네.','sailor'],
      ['허만복','배에서는 발밑도 살피고, 사람 말도 잘 들어야 해. 자, 이 매듭부터 한번 봐.','sailor']
    ]);
    else if(actor.id==='clerk')say([
      ['육승','수량 확인은 끝났습니다. 따로 봉한 귀물도 빠짐없이 실었고요.','clerk'],
      ['육승','그 귀물을 전달하면 약정된 보수를 받습니다. 수령인에게 인도할 때까지 조심해 주세요.','clerk']
    ]);
    else if(actor.id==='boarding'){
      if(!state.talkedCaptain){say([['안내','먼저 나루터의 표두 서문길에게 인사하자.','hero']]);return;}
      say([['주인공','배에 오르자. 첫 표행을 시작할 시간이다.','hero']],()=>transition('출항 · 동정호 수로',()=>{
        state.scene='deck';state.phase='explore';state.x=420;state.y=380;state.facing='up';setLocation('호송선 · 갑판');objective('갑판의 표두에게 출항 준비를 보고하세요.',2);log('닻이 올라갑니다. 나루터가 조금씩 멀어집니다.');
      }));
    } else if(actor.id==='deck-sailor')say([['허만복','물살은 괜찮군. 앞에 보이는 좁은 수로만 지나면 한동안 편할 거야.','sailor']]);
    else if(actor.id==='deck-captain')say([
      ['주인공','표두님, 갑판에 올라왔습니다.','hero'],
      ['서문길','좋다. 처음에는 내가 보이는 곳에 있어라. 무슨 일이 나면—','captain'],
      ['허만복','작은 배가 붙습니다! 저 표식은…… 흑린채입니다!','sailor'],
      ['서문길','모두 화물에서 떨어져라! 너는 이쪽 통로를 지켜. 무리해서 쫓지는 마라!','captain']
    ],()=>transition('흑린채 습격',()=>startBattle()));
  }
  function updateInteraction(){
    if(state.phase!=='explore'||state.dialogue){state.nearest=null;$('interaction').hidden=true;return;}
    let nearest=null,dist=62;for(const a of actors()){const d=Math.hypot(a.x-state.x,a.y-state.y);if(d<dist){dist=d;nearest=a;}}
    state.nearest=nearest;const el=$('interaction');el.hidden=!nearest;
    if(nearest){el.dataset.target=nearest.id;el.style.left=`${nearest.x/W*100}%`;el.style.top=`${(nearest.y-64)/H*100}%`;el.querySelector('span').textContent=nearest.action;}
  }
  function update(dt){
    if(state.phase!=='explore'||state.dialogue){state.moving=false;return;}
    let dx=0,dy=0;const keys=state.keys;
    if(keys.has('arrowleft')||keys.has('a'))dx--;if(keys.has('arrowright')||keys.has('d'))dx++;if(keys.has('arrowup')||keys.has('w'))dy--;if(keys.has('arrowdown')||keys.has('s'))dy++;
    if(dx||dy){state.path=[];const len=Math.hypot(dx,dy);dx/=len;dy/=len;}
    else if(state.path.length){const point=state.path[0],dist=Math.hypot(point.x-state.x,point.y-state.y);if(dist<3){state.x=point.x;state.y=point.y;state.path.shift();}else{dx=(point.x-state.x)/dist;dy=(point.y-state.y)/dist;}}
    const speed=125*dt,oldX=state.x,oldY=state.y;
    if(dx&&walkable(state.x+dx*speed,state.y))state.x+=dx*speed;if(dy&&walkable(state.x,state.y+dy*speed))state.y+=dy*speed;
    state.moving=Math.abs(oldX-state.x)+Math.abs(oldY-state.y)>.01;
    if(state.moving){state.footTime+=dt*11;if(Math.abs(dx)>Math.abs(dy))state.facing=dx>0?'right':'left';else state.facing=dy>0?'down':'up';}
    updateInteraction();
  }
  function loop(time){const dt=Math.min((time-state.lastTime)/1000||0,.1);state.lastTime=time;frameTime=time;update(dt);if(state.phase!=='battle'&&state.phase!=='end')drawScene(time);requestAnimationFrame(loop);}
  function reset(){
    state.epoch++;state.phase='title';state.scene='dock';state.started=false;state.talkedCaptain=false;state.x=310;state.y=410;state.facing='down';state.dialogue=null;state.nearest=null;state.selected=false;state.busy=false;clearMovement();
    for(const id of ['battle','dialogue','ending','transition','interaction'])$(id).hidden=true;
    $('title-screen').hidden=false;$('location').hidden=false;setLocation('동정호 남쪽 · 청류진 나루');objective('표행을 시작하세요.',-1);log('물결이 선착장을 두드립니다.');$('start-game').focus({preventScroll:true});
  }
  function start(){
    state.phase='explore';state.started=true;$('title-screen').hidden=true;objective('오른쪽 나루 끝의 표두 서문길과 대화하세요.',0);
    say([['주인공','오늘은 나의 첫 정식 표행이다. 출항 전에 표두님을 찾아뵙자.','hero']],()=>log('방향키 또는 WASD로 이동하고, 가까이에서 E로 대화하세요.'));
  }
  function updateHP(){
    $('player-hp-text').textContent=`${state.playerHP} / ${CONFIG.player.hp}`;$('enemy-hp-text').textContent=`${state.enemyHP} / ${CONFIG.enemy.hp}`;
    $('player-hp-bar').style.width=`${state.playerHP/CONFIG.player.hp*100}%`;$('enemy-hp-bar').style.width=`${state.enemyHP/CONFIG.enemy.hp*100}%`;
  }
  function startBattle(){
    state.epoch++;state.phase='battle';state.dialogue=null;state.selected=false;state.busy=false;state.playerHP=CONFIG.player.hp;state.enemyHP=CONFIG.enemy.hp;state.turn=1;clearMovement();
    $('title-screen').hidden=true;$('dialogue').hidden=true;$('location').hidden=true;$('interaction').hidden=true;$('ending').hidden=true;$('battle').hidden=false;$('damage-float').hidden=true;
    $('skill-samjae').setAttribute('aria-pressed','false');$('skill-samjae').disabled=false;$('use-skill').disabled=true;$('round-label').textContent='첫 번째 교전';$('detail-eyebrow').textContent='내 차례';$('skill-title').textContent='무공을 살펴보세요';$('skill-description').textContent='오른쪽 무공을 선택하면 설명을 확인할 수 있습니다.';$('skill-note').textContent='선택만으로는 턴을 소모하지 않습니다.';
    updateHP();objective('삼재검법을 선택하고 설명을 확인한 뒤 사용하세요.',3);log('흑린채 수적이 통로를 막아섰습니다.');$('skill-samjae').focus({preventScroll:true});
  }
  function selectSkill(){
    if(state.phase!=='battle'||state.busy)return;state.selected=true;$('skill-samjae').setAttribute('aria-pressed','true');$('skill-title').textContent='삼재검법';$('skill-description').textContent='근력 × 3 + 기민 × 2\n현재 방어 전 피해: 50';$('skill-note').textContent='부가 효과는 추후 설정됩니다.';$('use-skill').disabled=false;
    announce('삼재검법 설명. 근력 곱하기 3 더하기 기민 곱하기 2. 방어 전 피해 50. 사용 버튼을 누르면 공격합니다.');
  }
  function showDamage(value,target){const el=$('damage-float');el.hidden=false;el.className=`damage-float ${target}`;el.style.animation='none';void el.offsetWidth;el.style.animation='';el.textContent=`−${value}`;$('battle-scene').classList.remove('impact');void $('battle-scene').offsetWidth;$('battle-scene').classList.add('impact');}
  async function useSkill(){
    if(state.phase!=='battle'||!state.selected||state.busy)return;
    state.busy=true;$('use-skill').disabled=true;$('skill-samjae').disabled=true;const epoch=state.epoch;
    const raw=CONFIG.player.strength*3+CONFIG.player.agility*2,hit=damage(raw,CONFIG.enemy.constitution);
    $('detail-eyebrow').textContent='주인공의 공격';$('skill-title').textContent='삼재검법';$('skill-description').textContent='검끝을 바로 세워 수적의 빈틈을 찌릅니다.';$('skill-note').textContent='';
    await wait(CONFIG.hitDelay);if(epoch!==state.epoch)return;
    state.enemyHP=Math.max(0,state.enemyHP-hit);updateHP();showDamage(hit,'enemy');log(`삼재검법으로 ${hit} 피해를 주었습니다. 수적 체력 ${state.enemyHP}.`);
    $('skill-description').textContent=`삼재검법이 명중했습니다.\n수적에게 ${hit}의 피해를 주었습니다.`;
    await wait(CONFIG.returnDelay);if(epoch!==state.epoch)return;
    if(state.enemyHP===0){finishBattle();return;}
    $('detail-eyebrow').textContent='상대 차례';$('skill-title').textContent='수적의 반격';$('skill-description').textContent='흑린채 수적이 도를 휘두릅니다.';$('damage-float').hidden=true;
    await wait(CONFIG.hitDelay);if(epoch!==state.epoch)return;
    const counter=damage(CONFIG.enemy.rawDamage,CONFIG.player.constitution);state.playerHP=Math.max(0,state.playerHP-counter);updateHP();showDamage(counter,'player');log(`수적의 공격으로 ${counter} 피해를 받았습니다. 주인공 체력 ${state.playerHP}.`);
    await wait(CONFIG.returnDelay);if(epoch!==state.epoch)return;
    if(state.playerHP===0){state.busy=false;$('ending').querySelector('h2').textContent='다시 자세를 가다듬자';$('ending').querySelector('.chapter-label').textContent='전투 재도전';$('result-hp').textContent=`0 / ${CONFIG.player.hp}`;$('ending').hidden=false;state.phase='end';return;}
    state.turn++;state.busy=false;$('damage-float').hidden=true;$('skill-samjae').disabled=false;$('use-skill').disabled=false;$('round-label').textContent=`${state.turn}번째 교전`;$('detail-eyebrow').textContent='내 차례';$('skill-title').textContent='삼재검법';$('skill-description').textContent='근력 × 3 + 기민 × 2\n현재 방어 전 피해: 50';$('skill-note').textContent='부가 효과는 추후 설정됩니다.';
    $('use-skill').focus({preventScroll:true});
  }
  function finishBattle(){
    state.phase='end';state.busy=false;$('damage-float').hidden=true;$('ending').querySelector('h2').textContent='통로를 확보했다';$('ending').querySelector('.chapter-label').textContent='첫 번째 교전 · 완료';$('result-hp').textContent=`${state.playerHP} / ${CONFIG.player.hp}`;$('ending').hidden=false;
    objective('첫 전투를 마쳤습니다. 이번 데모는 여기까지입니다.',4);log('첫 승리. 갑판의 통로를 확보했습니다.');$('retry-battle').focus({preventScroll:true});
  }
  $('start-game').addEventListener('click',start);$('quick-battle').addEventListener('click',()=>{state.started=true;startBattle();});$('restart').addEventListener('click',reset);$('end-restart').addEventListener('click',reset);$('retry-battle').addEventListener('click',startBattle);$('next-dialogue').addEventListener('click',nextLine);$('touch-interact').addEventListener('click',interact);$('skill-samjae').addEventListener('click',selectSkill);$('use-skill').addEventListener('click',useSkill);
  canvas.addEventListener('click',event=>{
    if(state.phase!=='explore'||state.dialogue)return;canvas.focus({preventScroll:true});const r=canvas.getBoundingClientRect(),x=(event.clientX-r.left)/r.width*W,y=(event.clientY-r.top)/r.height*H;
    const clicked=actors().find(a=>Math.hypot(a.x-x,a.y-y)<28);if(clicked&&Math.hypot(clicked.x-state.x,clicked.y-state.y)<62){state.nearest=clicked;interact();return;}
    pathTo(x,y);
  });
  window.addEventListener('keydown',event=>{
    const key=event.key.toLowerCase();
    if(key==='e'&&!event.repeat){if(state.phase==='explore'||state.dialogue){event.preventDefault();interact();}return;}
    if(key==='enter'&&!event.repeat){
      if(state.dialogue){event.preventDefault();nextLine();return;}
      if(state.phase==='explore'){event.preventDefault();interact();return;}
      if(state.phase==='battle'){event.preventDefault();if(state.selected)useSkill();else selectSkill();return;}
    }
    if(['arrowup','arrowdown','arrowleft','arrowright','w','a','s','d'].includes(key)&&state.phase==='explore'&&!state.dialogue){event.preventDefault();state.keys.add(key);}
  });
  window.addEventListener('keyup',event=>state.keys.delete(event.key.toLowerCase()));window.addEventListener('blur',()=>{state.keys.clear();state.path=[];});
  document.addEventListener('visibilitychange',()=>{if(document.hidden)state.keys.clear();});
  const keyMap={up:'arrowup',down:'arrowdown',left:'arrowleft',right:'arrowright'};
  document.querySelectorAll('[data-dir]').forEach(button=>{
    button.addEventListener('pointerdown',event=>{event.preventDefault();button.setPointerCapture(event.pointerId);if(state.phase==='explore'&&!state.dialogue)state.keys.add(keyMap[button.dataset.dir]);});
    for(const name of ['pointerup','pointercancel','lostpointercapture'])button.addEventListener(name,()=>state.keys.delete(keyMap[button.dataset.dir]));
  });
  reset();requestAnimationFrame(loop);
})();
