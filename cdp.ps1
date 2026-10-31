$ErrorActionPreference = 'Stop'
function Connect-CDP {
  $pages = Invoke-RestMethod http://127.0.0.1:9222/json/list
  $page = $pages | Where-Object type -eq 'page' | Select-Object -First 1
  $script:socket = [System.Net.WebSockets.ClientWebSocket]::new()
  $script:socket.ConnectAsync([Uri]$page.webSocketDebuggerUrl, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
  $script:sequence = 0
  $script:events = [Collections.Generic.List[object]]::new()
}
function Send-CDP([string]$method, $parameters = @{}) {
  $script:sequence++
  $id = $script:sequence
  $json = @{ id = $id; method = $method; params = $parameters } | ConvertTo-Json -Depth 40 -Compress
  $bytes = [Text.Encoding]::UTF8.GetBytes($json)
  $script:socket.SendAsync([ArraySegment[byte]]::new($bytes), [Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
  do {
    $stream = [IO.MemoryStream]::new()
    do {
      $buffer = New-Object byte[] 65536
      $received = $script:socket.ReceiveAsync([ArraySegment[byte]]::new($buffer), [Threading.CancellationToken]::None).GetAwaiter().GetResult()
      $stream.Write($buffer, 0, $received.Count)
    } until ($received.EndOfMessage)
    $msg = [Text.Encoding]::UTF8.GetString($stream.ToArray()) | ConvertFrom-Json
    $stream.Dispose()
    if ($msg.method) { $script:events.Add($msg) }
  } until ($msg.id -eq $id)
  if ($msg.error) { throw ($msg.error | ConvertTo-Json -Compress) }
  return $msg.result
}
function Eval-JS([string]$expression) {
  $r = Send-CDP 'Runtime.evaluate' @{expression=$expression; returnByValue=$true; awaitPromise=$true}
  if ($r.exceptionDetails) { throw ($r.exceptionDetails | ConvertTo-Json -Depth 8) }
  return $r.result.value
}
function Save-Shot([string]$path, $clip = $null) {
  $p = @{format='png'; captureBeyondViewport=$false}
  if ($clip) { $p.clip = $clip }
  $r = Send-CDP 'Page.captureScreenshot' $p
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($r.data))
}
