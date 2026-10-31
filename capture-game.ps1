. "$PSScriptRoot/cdp.ps1"
$gameFiles = Get-ChildItem ../codex-p5js-KAEP0022 -File
$beforeHashes = @{}; foreach ($f in $gameFiles) {$beforeHashes[$f.Name] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash}
Connect-CDP
Send-CDP 'Runtime.enable' | Out-Null
Send-CDP 'Emulation.setDeviceMetricsOverride' @{width=1440;height=900;deviceScaleFactor=1;mobile=$false} | Out-Null
Send-CDP 'Page.navigate' @{url='file:///C:/Users/maiko/codex-project/codex-p5js-KAEP0022/index.html'} | Out-Null
Start-Sleep -Seconds 5
Eval-JS '({title:document.title,canvas:!!document.querySelector("canvas"),p5:typeof p5})' | ConvertTo-Json
Save-Shot (Join-Path (Get-Location) 'output/deck/assets/game-full.png')
$rect = Eval-JS '(()=>{const r=document.querySelector("#kitchen-map").getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,scale:1}})()'
Save-Shot (Join-Path (Get-Location) 'output/deck/assets/game-map.png') $rect
Eval-JS 'chooseStep("clean"); startCookingGame("cut",stationForStep("cut")); noLoop(); redraw();' | Out-Null
Start-Sleep -Milliseconds 250
$rect = Eval-JS '(()=>{const r=document.querySelector("#kitchen-map canvas").getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,scale:1}})()'
Save-Shot (Join-Path (Get-Location) 'output/deck/assets/game-cut.png') $rect
Eval-JS 'ui.recipe.value="macaron";resetGame();chooseStep("clean");chooseStep("measure");chooseStep("fold");startCookingGame("pipe",stationForStep("pipe"));redraw();' | Out-Null
Start-Sleep -Milliseconds 250
$rect = Eval-JS '(()=>{const r=document.querySelector("#kitchen-map canvas").getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,scale:1}})()'
Save-Shot (Join-Path (Get-Location) 'output/deck/assets/game-macaron.png') $rect
$script:events | Where-Object method -eq 'Runtime.exceptionThrown' | ConvertTo-Json -Depth 5
$changed=@($gameFiles | Where-Object {$beforeHashes[$_.Name] -ne (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash} | ForEach-Object Name)
@{gameSourceUnchanged=($changed.Count -eq 0);changedFiles=$changed;capturedAt=(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')} | ConvertTo-Json | Set-Content output/deck/preview/game-capture-check.json -Encoding UTF8
if($changed.Count -gt 0){throw 'Game source changed during capture'}
