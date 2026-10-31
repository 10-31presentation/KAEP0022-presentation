. "$PSScriptRoot/cdp.ps1"
Connect-CDP
Eval-JS 'document.fonts.ready.then(()=>({family:getComputedStyle(document.body).fontFamily,faces:[...document.fonts].map(f=>({family:f.family,weight:f.weight,status:f.status})),japanese:document.fonts.check("700 65px \"M PLUS Rounded 1c\"","\u6599\u7406"),english:document.fonts.check("500 19px \"M PLUS Rounded 1c\"","DANDORI KITCHEN")}))' | ConvertTo-Json -Depth 5 | Set-Content output/deck/preview/font-check.json -Encoding UTF8
Send-CDP 'DOM.enable' | Out-Null
$doc=Send-CDP 'DOM.getDocument'
$node=Send-CDP 'DOM.querySelector' @{nodeId=$doc.root.nodeId;selector='.slide.active h2, .slide.active h1'}
Send-CDP 'CSS.enable' | Out-Null
$actual=Send-CDP 'CSS.getPlatformFontsForNode' @{nodeId=$node.nodeId}
$actual | ConvertTo-Json -Depth 5 | Tee-Object -FilePath output/deck/preview/actual-font-check.json
