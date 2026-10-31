. "$PSScriptRoot/cdp.ps1"
Connect-CDP
Send-CDP 'Emulation.setDeviceMetricsOverride' @{width=1600;height=900;deviceScaleFactor=1;mobile=$false} | Out-Null
Send-CDP 'Emulation.setEmulatedMedia' @{media='print'} | Out-Null
$result=Eval-JS '({pages:[...document.querySelectorAll(".slide")].map(s=>({height:s.getBoundingClientRect().height,width:s.getBoundingClientRect().width,top:s.getBoundingClientRect().top,display:getComputedStyle(s).display})),controlsHidden:getComputedStyle(document.querySelector("#controls")).display==="none",allImagesLoaded:[...document.images].every(i=>i.complete&&i.naturalWidth>0),bodyHeight:document.body.scrollHeight})'
$result | ConvertTo-Json -Depth 6 | Tee-Object -FilePath output/deck/preview/print-check.json
Save-Shot (Join-Path (Get-Location) 'output/deck/preview/print-cover.png')
Eval-JS 'window.scrollTo(0,6300)' | Out-Null
Start-Sleep -Milliseconds 200
Save-Shot (Join-Path (Get-Location) 'output/deck/preview/print-slide08.png')
Send-CDP 'Emulation.setEmulatedMedia' @{media='screen'} | Out-Null
Eval-JS 'window.scrollTo(0,0);deck.show(0)' | Out-Null
