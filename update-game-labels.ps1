param([string]$EditsPath='tools/game-label-edits.json')
$ErrorActionPreference='Stop'
$gameRoot=[IO.Path]::GetFullPath((Join-Path (Get-Location) '../codex-p5js-KAEP0022'))
$edits=Get-Content -LiteralPath $EditsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$pending=@{}
foreach($edit in $edits){
  $path=Join-Path $gameRoot $edit.file
  if(!$pending.ContainsKey($path)){$pending[$path]=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)}
  $content=$pending[$path]
  if([regex]::Matches($content,[regex]::Escape($edit.old)).Count -ne 1){throw "Expected one matching text in $($edit.file)"}
  $pending[$path]=$content.Replace($edit.old,$edit.new)
}
$backup=Join-Path (Get-Location) ('tools/game-label-backup/'+(Get-Date -Format yyyyMMdd-HHmmss))
New-Item -ItemType Directory -Force $backup | Out-Null
foreach($path in $pending.Keys){Copy-Item -LiteralPath $path -Destination (Join-Path $backup ([IO.Path]::GetFileName($path)))}
foreach($path in $pending.Keys){[IO.File]::WriteAllText($path,$pending[$path],[Text.UTF8Encoding]::new($false));Write-Output ([IO.Path]::GetFileName($path)+' updated')}
