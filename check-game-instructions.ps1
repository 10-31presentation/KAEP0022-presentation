. "$PSScriptRoot/cdp.ps1"
Connect-CDP
Send-CDP 'Runtime.enable' | Out-Null
Send-CDP 'Emulation.setDeviceMetricsOverride' @{width=1440;height=900;deviceScaleFactor=1;mobile=$false} | Out-Null
Send-CDP 'Page.navigate' @{url='file:///C:/Users/maiko/codex-project/codex-p5js-KAEP0022/index.html'} | Out-Null
Start-Sleep -Seconds 5
Eval-JS 'document.fonts.ready' | Out-Null
Eval-JS 'startSelectedRecipe("stew")' | Out-Null
Start-Sleep -Milliseconds 400
Eval-JS 'chooseStep("clean");chooseStep("cut");startCookingGame("cook",stationForStep("cook"));noLoop();redraw();' | Out-Null
$vegetableText=Eval-JS 'cookingInstruction.textContent'
Save-Shot (Join-Path (Get-Location) 'output/deck/preview/game-vegetable-instruction.png')
Eval-JS 'closeCookingGame();chooseStep("cook");startCookingGame("cream",stationForStep("cream"));redraw();' | Out-Null
$mixText=Eval-JS 'cookingInstruction.textContent'
Save-Shot (Join-Path (Get-Location) 'output/deck/preview/game-mix-instruction.png')
$edits=Get-Content tools/game-instruction-edits.json -Raw -Encoding UTF8 | ConvertFrom-Json
$errors=@($script:events | Where-Object method -eq 'Runtime.exceptionThrown')
$result=@{vegetableInstruction=$vegetableText;mixInstruction=$mixText;vegetableMatches=($vegetableText -eq $edits[0].new);mixMatches=($mixText -eq $edits[1].new);consoleErrors=$errors}
$result | ConvertTo-Json -Depth 8 | Tee-Object -FilePath output/deck/preview/game-instruction-check.json
if(!$result.vegetableMatches -or !$result.mixMatches -or $errors.Count){throw 'Instruction verification failed'}
