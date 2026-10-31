$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$html=Get-Content "$PSScriptRoot/deck.template.html" -Raw -Encoding UTF8
foreach($name in @('game-map','game-full','game-cut','game-macaron')) {
  $data=[Convert]::ToBase64String([IO.File]::ReadAllBytes("$root/output/deck/assets/$name.png"))
  $html=$html.Replace("@@$name@@","data:image/png;base64,$data")
}
foreach($weight in @('Medium','Bold')) {
  $data=[Convert]::ToBase64String([IO.File]::ReadAllBytes("$root/output/deck/assets/MPLUSRounded1c-$weight.ttf"))
  $html=$html.Replace("@@font-$($weight.ToLower())@@","data:font/ttf;base64,$data")
}
foreach($asset in @(@{name='chalk-heart';extension='gif';mime='image/gif'},@{name='question-mark';extension='gif';mime='image/gif'},@{name='cover-sparkle';extension='gif';mime='image/gif'},@{name='cover-sparkle-poster';extension='png';mime='image/png'})) {
  $data=[Convert]::ToBase64String([IO.File]::ReadAllBytes("$root/output/deck/assets/$($asset.name).$($asset.extension)"))
  $html=$html.Replace("@@$($asset.name)@@","data:$($asset.mime);base64,$data")
}
$license=Get-Content "$root/output/deck/assets/MPLUSRounded1c-OFL.txt" -Raw -Encoding UTF8
$html=$html.Replace('@@font-license@@',$license.Replace('--','- -'))
if($html -match '@@[a-z-]+@@'){throw 'Unresolved template placeholder'}
[IO.File]::WriteAllText("$root/output/deck/index.html",$html,[Text.UTF8Encoding]::new($false))
Write-Output 'Built self-contained HTML with embedded M PLUS Rounded 1c.'
