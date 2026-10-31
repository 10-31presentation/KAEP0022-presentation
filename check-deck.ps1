. "$PSScriptRoot/cdp.ps1"
Connect-CDP
Send-CDP 'Runtime.enable' | Out-Null
Send-CDP 'Log.enable' | Out-Null
Send-CDP 'Emulation.setDeviceMetricsOverride' @{width=1440;height=810;deviceScaleFactor=1;mobile=$false} | Out-Null
Send-CDP 'Page.navigate' @{url='file:///C:/Users/maiko/codex-project/codex-presentation/output/deck/index.html'} | Out-Null
Start-Sleep -Seconds 2
$slideCount = [int](Eval-JS 'deck.count')
$checks = @()
for($i=0;$i -lt $slideCount;$i++) {
  Eval-JS "deck.show($i)" | Out-Null
  Start-Sleep -Milliseconds 1650
  $checks += Eval-JS @'
(()=>{const s=document.querySelector('.slide.active'),bounds=s.getBoundingClientRect(),bad=[];
for(const e of s.querySelectorAll('h1,h2,h3,p,figure,img,.bubble,.play-step,.design-note,.learning-node,.future-path,.cover-tag,.cover-meta')){
const r=e.getBoundingClientRect();if(r.left<bounds.left-1||r.top<bounds.top-1||r.right>bounds.right+1||r.bottom>bounds.bottom-1)bad.push({kind:'outside',tag:e.tagName,cls:e.className});if(e.scrollWidth>e.clientWidth+2&&e.clientWidth)bad.push({kind:'horizontal-overflow',cls:e.className});}
const textNodes=[];const w=document.createTreeWalker(s,NodeFilter.SHOW_TEXT);let n;while(n=w.nextNode())if(n.textContent.trim()){const rg=document.createRange();rg.selectNodeContents(n);for(const r of rg.getClientRects())if(r.width&&r.height)textNodes.push({r,t:n.textContent.trim().slice(0,35),parent:n.parentElement});}
const scale=bounds.width/1600,ctrl=document.getElementById('controls').getBoundingClientRect();
for(const x of textNodes){if(x.r.top<bounds.top+51*scale||x.r.bottom>bounds.top+854*scale)bad.push({kind:'frill-clearance',text:x.t});if(Math.min(x.r.right,ctrl.right)-Math.max(x.r.left,ctrl.left)>3&&Math.min(x.r.bottom,ctrl.bottom)-Math.max(x.r.top,ctrl.top)>3)bad.push({kind:'controls-overlap',text:x.t});}
for(let a=0;a<textNodes.length;a++)for(let b=a+1;b<textNodes.length;b++){const x=textNodes[a],y=textNodes[b];if(x.parent===y.parent)continue;const ix=Math.min(x.r.right,y.r.right)-Math.max(x.r.left,y.r.left),iy=Math.min(x.r.bottom,y.r.bottom)-Math.max(x.r.top,y.r.top);if(ix>3&&iy>3)bad.push({kind:'text-overlap',a:x.t,b:y.t});}
return {page:deck.current+1,title:s.getAttribute('aria-label'),stage:{width:bounds.width,height:bounds.height},issues:bad,images:[...s.querySelectorAll('img')].every(x=>x.complete&&x.naturalWidth>0)};})()
'@
  Save-Shot (Join-Path (Get-Location) ('output/deck/preview/slide-{0:00}.png' -f ($i+1)))
}
$checks | ConvertTo-Json -Depth 10 | Set-Content output/deck/preview/layout-check.json -Encoding UTF8
Eval-JS 'deck.show(0)' | Out-Null
Send-CDP 'Input.dispatchKeyEvent' @{type='keyDown';key='ArrowRight';code='ArrowRight';windowsVirtualKeyCode=39} | Out-Null
$right=Eval-JS 'deck.current===1'
Send-CDP 'Input.dispatchKeyEvent' @{type='keyDown';key='ArrowLeft';code='ArrowLeft';windowsVirtualKeyCode=37} | Out-Null
$left=Eval-JS 'deck.current===0'
Send-CDP 'Input.dispatchMouseEvent' @{type='mousePressed';x=700;y=420;button='left';clickCount=1} | Out-Null
Send-CDP 'Input.dispatchMouseEvent' @{type='mouseReleased';x=700;y=420;button='left';clickCount=1} | Out-Null
$click=Eval-JS 'deck.current===1'
$before=Eval-JS 'document.getElementById("timer").textContent'
Start-Sleep -Milliseconds 1200
$after=Eval-JS 'document.getElementById("timer").textContent'
$reset=Eval-JS 'document.getElementById("reset-time").click();document.getElementById("timer").textContent==="00:00"&&deck.current===1'
$errors=@($script:events | Where-Object { $_.method -eq 'Runtime.exceptionThrown' -or ($_.method -eq 'Log.entryAdded' -and $_.params.entry.level -eq 'error') })
$result=@{pages=$slideCount;layout=$checks;keyboardRight=$right;keyboardLeft=$left;clickNext=$click;timerTicks=($before -ne $after);timerReset=$reset;consoleErrors=$errors;externalResources=(Eval-JS '[...document.querySelectorAll("script[src],link[href],img[src]")].map(x=>x.src||x.href).filter(x=>/^https?:/.test(x))')}
$result | ConvertTo-Json -Depth 12 | Set-Content output/deck/preview/verification.json -Encoding UTF8
$result | ConvertTo-Json -Depth 7
