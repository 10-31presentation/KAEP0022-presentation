. "$PSScriptRoot/cdp.ps1"
Connect-CDP
Eval-JS 'document.documentElement.classList.remove("export");deck.show(0)' | Out-Null
Start-Sleep -Seconds 2
$clip=Eval-JS '(()=>{const r=document.querySelector(".cover-sparkles").getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,scale:1}})()'
$hashes=@()
for($i=0;$i -lt 6;$i++){
  $path=Join-Path (Get-Location) "output/deck/preview/gif-motion-$i.png"
  Save-Shot $path $clip
  $hashes+=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  Start-Sleep -Milliseconds 500
}
$unique=@($hashes | Select-Object -Unique).Count
$screen=Eval-JS 'getComputedStyle(document.querySelector(".sparkle-motion")).display!=="none"'
Eval-JS 'document.documentElement.classList.add("export")' | Out-Null
$static=Eval-JS 'getComputedStyle(document.querySelector(".sparkle-motion")).display==="none"&&getComputedStyle(document.querySelector(".sparkle-still")).display!=="none"'
Eval-JS 'document.documentElement.classList.remove("export")' | Out-Null
@{animatedInBrowser=($unique -gt 1);differentFrames=$unique;animationVisible=$screen;staticExport=$static} | ConvertTo-Json | Tee-Object -FilePath output/deck/preview/animation-check.json
if($unique -le 1 -or !$screen -or !$static){throw 'Animation verification failed'}
