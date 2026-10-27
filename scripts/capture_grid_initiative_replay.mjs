// Run against a task-owned Chromium with --remote-debugging-port=9223.
import {writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
const pages=await (await fetch('http://127.0.0.1:9223/json')).json();
const page=pages.find(p=>p.type==='page');
const ws=new WebSocket(page.webSocketDebuggerUrl);await new Promise(r=>ws.addEventListener('open',r,{once:true}));
let next=0;const pending=new Map();const errors=[];
ws.addEventListener('message',e=>{const m=JSON.parse(e.data);if(m.method==='Runtime.exceptionThrown')errors.push(m.params.exceptionDetails.text);if(pending.has(m.id)){pending.get(m.id)(m);pending.delete(m.id)}});
function call(method,params={}){return new Promise((resolve,reject)=>{const id=++next;const timeout=setTimeout(()=>reject(new Error('CDP timeout: '+method)),12000);pending.set(id,m=>{clearTimeout(timeout);m.error?reject(new Error(JSON.stringify(m.error))):resolve(m.result)});ws.send(JSON.stringify({id,method,params}))})}
async function evaluate(expression){const r=await call('Runtime.evaluate',{expression,returnByValue:true});if(r.exceptionDetails)throw new Error(JSON.stringify(r.exceptionDetails));return r.result.value}
await call('Runtime.enable');await call('Page.enable');await call('Emulation.setDeviceMetricsOverride',{width:1440,height:1200,deviceScaleFactor:1,mobile:false});
await call('Page.navigate',{url:'http://127.0.0.1:8765/index.html'});
let ready=false;for(let i=0;i<40;i++){ready=await evaluate("document.body?.dataset.ready==='true'");if(ready)break;await new Promise(r=>setTimeout(r,200))}if(!ready)throw new Error('Replay did not initialize: '+errors.join(','));
const audited=await evaluate(`(()=>{let n=0;for(const c of data.cases){$('profile').value=c.control?'control':c.profile;$('hp').value=String(c.hp_scale);$('layout').value=c.layout.id;$('recovery').value=c.recovery;selectCase();if(current!==c)throw Error('Wrong case');for(const i of [0,c.frames.length-1]){frame=i;render();if($('board').children.length!==35)throw Error('Grid size');if(document.querySelectorAll('.token').length!==2)throw Error('Actor count')}n++}return n})()`);
if(audited!==31||errors.length)throw new Error('Replay audit: '+JSON.stringify({audited,errors}));
for(const [hp,index,name] of [[1,3,'actual'],[4,7,'endurance']]){
 await evaluate(`$('profile').value='agility';$('hp').value='${hp}';$('layout').value='centre';$('recovery').value='clock';selectCase();frame=${index};render()`);
 await new Promise(r=>setTimeout(r,200));
 const r=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:true});
 writeFileSync(resolve('prototypes/grid-initiative-simulation/'+name+'.png'),Buffer.from(r.data,'base64'));
}
console.log('GRID_REPLAY_BROWSER: PASS / '+audited+' selectable cases / 35 cells / 2 actors');ws.close();
