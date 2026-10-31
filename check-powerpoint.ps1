$ErrorActionPreference='Stop'
$app=$null;$deck=$null
try {
  $app=New-Object -ComObject PowerPoint.Application
  $deck=$app.Presentations.Open((Join-Path (Get-Location) 'output/deck/presentation.pptx'),-1,0,0)
  $count=$deck.Slides.Count
  $shapeCounts=@()
  for($i=1;$i -le $count;$i++){$shapeCounts+=$deck.Slides.Item($i).Shapes.Count}
  $deck.Slides.Item(1).Export((Join-Path (Get-Location) 'output/deck/preview/powerpoint-cover.png'),'PNG',1440,810)
  $deck.Slides.Item(8).Export((Join-Path (Get-Location) 'output/deck/preview/powerpoint-slide08.png'),'PNG',1440,810)
  @{openedInPowerPoint=$true;slides=$count;widthPoints=$deck.PageSetup.SlideWidth;heightPoints=$deck.PageSetup.SlideHeight;shapesPerSlide=$shapeCounts} | ConvertTo-Json | Tee-Object -FilePath output/deck/preview/powerpoint-check.json
} finally {
  if($deck){$deck.Close();[Runtime.InteropServices.Marshal]::FinalReleaseComObject($deck)|Out-Null}
  if($app){$app.Quit();[Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)|Out-Null}
}
