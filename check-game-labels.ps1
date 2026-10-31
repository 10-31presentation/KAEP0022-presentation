. "$PSScriptRoot/cdp.ps1"
Connect-CDP
Send-CDP 'Runtime.enable' | Out-Null
Send-CDP 'Log.enable' | Out-Null
Send-CDP 'Emulation.setDeviceMetricsOverride' @{width=1440;height=900;deviceScaleFactor=1;mobile=$false} | Out-Null
Send-CDP 'Page.navigate' @{url='file:///C:/Users/maiko/codex-project/codex-p5js-KAEP0022/index.html'} | Out-Null
Start-Sleep -Seconds 5
Eval-JS 'document.fonts.ready' | Out-Null
Eval-JS 'startSelectedRecipe("stew");' | Out-Null
Start-Sleep -Milliseconds 400
Eval-JS 'chooseStep("clean");chooseStep("cut");startCookingGame("cook",stationForStep("cook"));noLoop();redraw();' | Out-Null
Start-Sleep -Milliseconds 300
Save-Shot (Join-Path (Get-Location) 'output/deck/preview/game-vegetables-no-labels.png')
$checks=Eval-JS @'
(()=>{
const g=cookingGame;
const namesHidden=!drawVegetableOrder.toString().includes('cookingLabel(vegetable.name');
const answerHidden=!drawVegetableOrder.toString().includes('\u306b\u3093\u3058\u3093')&&!cookingInstruction.textContent.includes('\u306b\u3093\u3058\u3093');
const wrong=g.vegetables.findIndex(v=>v.rank===1);g.selected=wrong;g.travel=0;endVegetableOrder(g.vegetables[wrong]);
const wrongBlocked=g.progress===0&&g.mistakes===1;
for(let rank=0;rank<3;rank++){const i=g.vegetables.findIndex(v=>v.rank===rank);g.selected=i;g.travel=0;endVegetableOrder(g.vegetables[i]);}
redraw();
return {namesHidden,answerHidden,wrongBlocked,correctOrderCompletes:g.complete&&g.progress===3&&g.vegetables.every(v=>v.done)};
})()
'@
$errors=@($script:events | Where-Object { $_.method -eq 'Runtime.exceptionThrown' -or ($_.method -eq 'Log.entryAdded' -and $_.params.entry.level -eq 'error') })
@{checks=$checks;consoleErrors=$errors} | ConvertTo-Json -Depth 8 | Tee-Object -FilePath output/deck/preview/game-label-check.json
if(!$checks.namesHidden -or !$checks.answerHidden -or !$checks.wrongBlocked -or !$checks.correctOrderCompletes -or $errors.Count){throw 'Game check failed'}
