. "$PSScriptRoot/cdp.ps1"
Connect-CDP
Send-CDP 'Runtime.enable' | Out-Null
Send-CDP 'Emulation.setDeviceMetricsOverride' @{width=1440;height=900;deviceScaleFactor=1;mobile=$false} | Out-Null
Send-CDP 'Page.navigate' @{url='file:///C:/Users/maiko/codex-project/codex-p5js-KAEP0022/index.html'} | Out-Null
Start-Sleep -Seconds 5
Eval-JS 'document.fonts.ready' | Out-Null
$checks=Eval-JS @'
(()=>{
noLoop();const results=[];
for(const key of ['stew','macaron']){
  startSelectedRecipe(key);chooseStep('cut' in recipes[key].steps?'cut':recipe.steps[1].id);
  const warningVisible=!ui['feedback-text'].hidden&&ui['feedback-text'].textContent.length>0;
  startSelectedRecipe(key);startCookingGame('clean',stationForStep('clean'));
  const activeLabel=ui['feedback-label'].textContent;
  const duringHidden=ui['feedback-text'].hidden&&ui['feedback-text'].textContent==='';
  closeCookingGame();chooseStep('clean');
  const successLabel=ui['feedback-label'].textContent;
  const afterHidden=ui['feedback-text'].hidden&&ui['feedback-text'].textContent==='';
  for(const s of recipe.steps)chooseStep(s.id);
  const finishedHidden=ui['feedback-text'].hidden&&ui['feedback-text'].textContent==='';
  results.push({recipe:key,activeLabel,successLabel,duringHidden,afterHidden,finishedHidden,warningVisible,resultAvailable:!ui.result.hidden});
}
startSelectedRecipe('stew');startCookingGame('clean',stationForStep('clean'));redraw();
return results;
})()
'@
Start-Sleep -Milliseconds 300
Save-Shot (Join-Path (Get-Location) 'output/deck/preview/game-feedback-short.png')
$errors=@($script:events | Where-Object method -eq 'Runtime.exceptionThrown')
@{checks=$checks;consoleErrors=$errors} | ConvertTo-Json -Depth 8 | Tee-Object -FilePath output/deck/preview/game-feedback-check.json
if(@($checks | Where-Object {!$_.duringHidden -or !$_.afterHidden -or !$_.finishedHidden -or !$_.warningVisible -or !$_.resultAvailable}).Count -gt 0 -or $errors.Count){throw 'Feedback verification failed'}
