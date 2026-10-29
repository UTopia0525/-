from pathlib import Path
from playwright.sync_api import sync_playwright
root=Path(__file__).resolve().parents[1]
html=(root/'world-map/index.html').read_text()
css='''<style>
.city text,.faction text,.camp text,.watercamp text,.urbanfaction text{font-weight:400;opacity:.75}
.implemented text{font-weight:900!important;font-size:17px!important;fill:#172c36!important;opacity:1!important;stroke:#f4df9b!important;stroke-width:5px!important;paint-order:stroke;stroke-linejoin:round}
.implemented .marker,.implemented circle{fill:#bd8428!important;stroke:#fff1b3!important}
.app{grid-template-columns:minmax(0,1fr) 310px}aside strong{color:#ffe19b;font-weight:900}aside li{margin:9px 0;line-height:1.7;font-size:14px}
header p{font-size:15px}.legend{line-height:1.8}
</style>'''
js='''<script>
for(const id of ['changsha','wuchang','nanjing','namgung','qingya','suzhou','murong','hangzhou','blackguild'])document.querySelector('[data-id="'+id+'"]').classList.add('implemented');
const p=xy(115.5,30.5),hamlet=el('g',{class:'implemented'},world);
el('circle',{cx:p[0],cy:p[1],r:5.5,fill:'#bd8428',stroke:'#fff1b3','stroke-width':2},hamlet);
const name=el('text',{x:p[0]+12,y:p[1]+26},hamlet);name.textContent='삼거리 산촌';
el('line',{x1:p[0],y1:p[1],x2:p[0]+12,y2:p[1]+15,stroke:'#725e31'},hamlet);
document.querySelector('header h1').textContent='명초 강호도 · 전체 지도';
document.querySelector('header p').textContent='1390년경 · 굵은 이름과 금색 표시는 실제 플레이 맵이 구현된 곳';
document.querySelector('nav').style.display='none';
document.querySelector('.legend').innerHTML='<strong>굵은 이름·금색: 구현 완료</strong>　보통 이름: 세계관 설정/예정 지역<br>● 도시　▲ 구파일방　■ 오대세가　⬟ 녹림 산채　◆ 수채　✚ 도시 사파';
document.querySelector('.small').textContent='구현 여부는 지형·탐험 맵 기준이며, 해당 세력의 모든 이야기나 건물 내부가 완성되었다는 뜻은 아닙니다.';
document.getElementById('details').innerHTML='<span class="badge">현재 구현 현황 · 2026-10-29</span><h2>플레이 가능한 지역</h2><ul><li><strong>장사 · 장사–무창 산길</strong></li><li><strong>무창</strong><br>무림맹 외원·총무당 실내</li><li><strong>삼거리 산촌 · 청애채</strong></li><li><strong>남경 · 남궁세가 본가</strong></li><li><strong>남경–소주 산길 · 소주</strong></li><li><strong>모용세가 장원</strong></li><li><strong>소주–항주 운하길 · 항주</strong><br>취월루 실내·운하 창고·서호 유람선 경관</li><li><strong>흑도방 본당</strong><br>본당 실내 구현 · 본부 장원 외부는 미구현</li></ul><h3>0장 별도 맵</h3><p><strong>나루터 · 호송선 갑판</strong><br>흑린채 수적 선상 전투 포함.<br>흑린채 본거지는 미구현.</p><h3>현재 연결</h3><p><strong>장사 → 무창 → 삼거리 산촌 → 남경 → 소주 → 운하길 → 항주</strong></p><p>산촌에서 청애채, 남경에서 남궁세가, 소주에서 모용세가로 분기합니다. 항주에서 취월루·창고·흑도방 본당으로 이동합니다.</p><p class="small">다른 도시·문파·산채는 설정상의 거점입니다. 이동 조건은 기존 이야기 진행을 따릅니다.</p>';
</script>'''
html=html+css+js
out=root/'docs/world-map-progress.html';out.write_text(html)
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 page=browser.new_page(viewport={'width':1500,'height':1300},device_scale_factor=1.5)
 page.set_content(html);page.wait_for_timeout(500)
 assert page.locator('.implemented').count()==10
 assert page.locator('[data-id="heilin"]').evaluate('(n)=>!n.classList.contains("implemented")')
 page.screenshot(path=str(root/'docs/world-map-progress.png'),full_page=True)
 browser.close()
print('world-map-progress: 10 named sites highlighted; separate interior/road/prologue noted')
