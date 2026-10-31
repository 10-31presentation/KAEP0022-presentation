. "$PSScriptRoot/cdp.ps1"
Connect-CDP
Send-CDP 'Runtime.enable' | Out-Null
Send-CDP 'Emulation.setDeviceMetricsOverride' @{width=1440;height=900;deviceScaleFactor=1;mobile=$false} | Out-Null
Send-CDP 'Page.navigate' @{url='file:///C:/Users/maiko/codex-project/codex-p5js-KAEP0022/index.html'} | Out-Null
Start-Sleep -Seconds 5
Eval-JS 'document.fonts.ready' | Out-Null
$checks=Eval-JS @'
(()=>{
  noLoop();
  const results=[],doneText=String.fromCharCode(0x3067,0x304d,0x305f,0xff01);
  for(const key of ['stew','macaron']){
    const ids=recipes[key].steps.map(s=>s.id);
    for(const id of ids){
      startSelectedRecipe(key);
      for(const step of recipe.steps){if(step.id===id)break;chooseStep(step.id);}
      startCookingGame(id,stationForStep(id));
      const g=cookingGame;
      if(g.mode==='plating'){
        for(let i=0;i<g.items.length;i++){
          beginFreePlating({x:g.items[i].x,y:g.items[i].y});
          endFreePlating({x:560,y:247},false);
        }
      }else{finishCookingAction();}
      const labels=[],original=cookingLabel;
      cookingLabel=function(...args){labels.push(String(args[0]));return original(...args)};
      try{redraw();}finally{cookingLabel=original;}
      results.push({recipe:key,step:id,complete:g.complete,oneCanvasMessage:labels.filter(t=>t.includes(doneText)).length===1,noDuplicateInPanel:!cookingInstruction.textContent.includes(doneText),completionButtonEnabled:!cookingCommit.disabled});
    }
  }
  return results;
})()
'@
Save-Shot (Join-Path (Get-Location) 'output/deck/preview/macaron-one-completion.png')
Eval-JS 'startSelectedRecipe("stew");startCookingGame("clean",stationForStep("clean"));finishCookingAction();redraw();' | Out-Null
Save-Shot (Join-Path (Get-Location) 'output/deck/preview/stew-one-completion.png')
$errors=@($script:events | Where-Object method -eq 'Runtime.exceptionThrown')
@{checks=$checks;consoleErrors=$errors} | ConvertTo-Json -Depth 8 | Tee-Object -FilePath output/deck/preview/game-completion-check.json
if(@($checks | Where-Object {!$_.complete -or !$_.oneCanvasMessage -or !$_.noDuplicateInPanel -or !$_.completionButtonEnabled}).Count -gt 0 -or $errors.Count){throw 'Completion message check failed'}
