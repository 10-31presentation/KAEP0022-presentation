. "$PSScriptRoot/cdp.ps1"
Connect-CDP
Send-CDP 'Runtime.enable' | Out-Null
Send-CDP 'Emulation.setDeviceMetricsOverride' @{width=1440;height=900;deviceScaleFactor=1;mobile=$false} | Out-Null
Send-CDP 'Page.navigate' @{url='file:///C:/Users/maiko/codex-project/codex-p5js-KAEP0022/index.html'} | Out-Null
Start-Sleep -Seconds 5
Eval-JS 'document.fonts.ready' | Out-Null
Eval-JS 'startSelectedRecipe("stew")' | Out-Null
Start-Sleep -Milliseconds 300
Eval-JS 'for(const step of recipe.steps){if(step.id==="serve")break;chooseStep(step.id);}startCookingGame("serve",stationForStep("serve"));noLoop();redraw();' | Out-Null
$actual=Eval-JS 'cookingInstruction.textContent'
$expected=(Get-Content tools/game-pour-instruction-edits.json -Raw -Encoding UTF8 | ConvertFrom-Json)[0].new
Save-Shot (Join-Path (Get-Location) 'output/deck/preview/game-pour-instruction.png')
$errors=@($script:events | Where-Object method -eq 'Runtime.exceptionThrown')
@{instruction=$actual;matches=($actual -eq $expected);consoleErrors=$errors} | ConvertTo-Json -Depth 8 | Tee-Object -FilePath output/deck/preview/game-pour-instruction-check.json
if($actual -ne $expected -or $errors.Count){throw 'Pour instruction check failed'}
