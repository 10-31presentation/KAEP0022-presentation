. "$PSScriptRoot/cdp.ps1"
$report = Get-Content output/deck/preview/verification.json -Raw -Encoding UTF8 | ConvertFrom-Json
if (@($report.layout | Where-Object {$_.issues.Count -gt 0 -or !$_.images}).Count -gt 0) { throw 'Resolve layout issues before export.' }
Connect-CDP
Send-CDP 'Emulation.setDeviceMetricsOverride' @{width=1600;height=900;deviceScaleFactor=1;mobile=$false} | Out-Null
Send-CDP 'Page.navigate' @{url='file:///C:/Users/maiko/codex-project/codex-presentation/output/deck/index.html'} | Out-Null
Start-Sleep -Seconds 1
Eval-JS 'document.documentElement.classList.add("export");document.fonts.ready.then(()=>Promise.all([...document.images].map(i=>i.decode())))' | Out-Null
$slideCount = [int](Eval-JS 'deck.count')
if($report.pages -ne $slideCount){throw 'HTML count differs from verified count'}
New-Item -ItemType Directory -Force output/deck/preview/export | Out-Null
for($i=0;$i -lt $slideCount;$i++) {
  Eval-JS "deck.show($i)" | Out-Null
  Start-Sleep -Milliseconds 100
  Save-Shot (Join-Path (Get-Location) ('output/deck/preview/export/slide-{0:00}.png' -f ($i+1)))
}
$pdf = Send-CDP 'Page.printToPDF' @{printBackground=$true;preferCSSPageSize=$true;displayHeaderFooter=$false;marginTop=0;marginBottom=0;marginLeft=0;marginRight=0;paperWidth=(1600/96);paperHeight=(900/96);generateTaggedPDF=$true}
$pdfPath = Join-Path (Get-Location) 'output/deck/presentation.pdf'
[IO.File]::WriteAllBytes($pdfPath, [Convert]::FromBase64String($pdf.data))
$pdfText = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($pdfPath))
$pdfCount = [regex]::Matches($pdfText, '/Type\s*/Page\b').Count
if ($pdfCount -ne $slideCount) { throw "PDF count is $pdfCount, expected $slideCount" }
Write-Output "PDF: $pdfCount pages"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$pptxPath = Join-Path (Get-Location) 'output/deck/presentation.pptx'
$file = [IO.File]::Open($pptxPath,[IO.FileMode]::Create)
$zip = [IO.Compression.ZipArchive]::new($file,[IO.Compression.ZipArchiveMode]::Create)
function Add-Xml([string]$name,[string]$xml) {
  [xml]$parsed = $xml
  $entry=$zip.CreateEntry($name,[IO.Compression.CompressionLevel]::Optimal)
  $stream=$entry.Open();$bytes=[Text.Encoding]::UTF8.GetBytes($xml);$stream.Write($bytes,0,$bytes.Length);$stream.Dispose()
}
$p='http://schemas.openxmlformats.org/presentationml/2006/main'
$a='http://schemas.openxmlformats.org/drawingml/2006/main'
$r='http://schemas.openxmlformats.org/officeDocument/2006/relationships'
$rel='http://schemas.openxmlformats.org/package/2006/relationships'
$types='<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/><Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/><Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/><Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
$ids='';$rels="<Relationships xmlns=`"$rel`"><Relationship Id=`"rId1`" Type=`"$r/slideMaster`" Target=`"slideMasters/slideMaster1.xml`"/>"
$group='<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>'
for($i=1;$i -le $slideCount;$i++) {
  $id=$i+1;$sid=255+$i
  $types+="<Override PartName=`"/ppt/slides/slide$i.xml`" ContentType=`"application/vnd.openxmlformats-officedocument.presentationml.slide+xml`"/>"
  $ids+="<p:sldId id=`"$sid`" r:id=`"rId$id`"/>"
  $rels+="<Relationship Id=`"rId$id`" Type=`"$r/slide`" Target=`"slides/slide$i.xml`"/>"
  $source=Join-Path (Get-Location) ('output/deck/preview/export/slide-{0:00}.png' -f $i)
  [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$source,"ppt/media/image$i.png",[IO.Compression.CompressionLevel]::Optimal) | Out-Null
  Add-Xml "ppt/slides/slide$i.xml" "<p:sld xmlns:a=`"$a`" xmlns:r=`"$r`" xmlns:p=`"$p`"><p:cSld name=`"Slide $i`"><p:spTree>$group<p:pic><p:nvPicPr><p:cNvPr id=`"2`" name=`"Slide $i image`" descr=`"Presentation page $i`"/><p:cNvPicPr><a:picLocks noChangeAspect=`"1`"/></p:cNvPicPr><p:nvPr/></p:nvPicPr><p:blipFill><a:blip r:embed=`"rId2`"/><a:stretch><a:fillRect/></a:stretch></p:blipFill><p:spPr><a:xfrm><a:off x=`"0`" y=`"0`"/><a:ext cx=`"12192000`" cy=`"6858000`"/></a:xfrm><a:prstGeom prst=`"rect`"><a:avLst/></a:prstGeom></p:spPr></p:pic></p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>"
  Add-Xml "ppt/slides/_rels/slide$i.xml.rels" "<Relationships xmlns=`"$rel`"><Relationship Id=`"rId1`" Type=`"$r/slideLayout`" Target=`"../slideLayouts/slideLayout1.xml`"/><Relationship Id=`"rId2`" Type=`"$r/image`" Target=`"../media/image$i.png`"/></Relationships>"
}
Add-Xml '[Content_Types].xml' ($types+'</Types>')
Add-Xml '_rels/.rels' "<Relationships xmlns=`"$rel`"><Relationship Id=`"rId1`" Type=`"$r/officeDocument`" Target=`"ppt/presentation.xml`"/><Relationship Id=`"rId2`" Type=`"http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties`" Target=`"docProps/core.xml`"/><Relationship Id=`"rId3`" Type=`"$r/extended-properties`" Target=`"docProps/app.xml`"/></Relationships>"
Add-Xml 'ppt/presentation.xml' "<p:presentation xmlns:a=`"$a`" xmlns:r=`"$r`" xmlns:p=`"$p`"><p:sldMasterIdLst><p:sldMasterId id=`"2147483648`" r:id=`"rId1`"/></p:sldMasterIdLst><p:sldIdLst>$ids</p:sldIdLst><p:sldSz cx=`"12192000`" cy=`"6858000`" type=`"screen16x9`"/><p:notesSz cx=`"6858000`" cy=`"9144000`"/></p:presentation>"
Add-Xml 'ppt/_rels/presentation.xml.rels' ($rels+'</Relationships>')
Add-Xml 'ppt/slideMasters/slideMaster1.xml' "<p:sldMaster xmlns:a=`"$a`" xmlns:r=`"$r`" xmlns:p=`"$p`"><p:cSld><p:spTree>$group</p:spTree></p:cSld><p:clrMap accent1=`"accent1`" accent2=`"accent2`" accent3=`"accent3`" accent4=`"accent4`" accent5=`"accent5`" accent6=`"accent6`" bg1=`"lt1`" bg2=`"lt2`" folHlink=`"folHlink`" hlink=`"hlink`" tx1=`"dk1`" tx2=`"dk2`"/><p:sldLayoutIdLst><p:sldLayoutId id=`"2147483649`" r:id=`"rId1`"/></p:sldLayoutIdLst><p:txStyles><p:titleStyle/><p:bodyStyle/><p:otherStyle/></p:txStyles></p:sldMaster>"
Add-Xml 'ppt/slideMasters/_rels/slideMaster1.xml.rels' "<Relationships xmlns=`"$rel`"><Relationship Id=`"rId1`" Type=`"$r/slideLayout`" Target=`"../slideLayouts/slideLayout1.xml`"/><Relationship Id=`"rId2`" Type=`"$r/theme`" Target=`"../theme/theme1.xml`"/></Relationships>"
Add-Xml 'ppt/slideLayouts/slideLayout1.xml' "<p:sldLayout xmlns:a=`"$a`" xmlns:r=`"$r`" xmlns:p=`"$p`" type=`"blank`" preserve=`"1`"><p:cSld name=`"Blank`"><p:spTree>$group</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>"
Add-Xml 'ppt/slideLayouts/_rels/slideLayout1.xml.rels' "<Relationships xmlns=`"$rel`"><Relationship Id=`"rId1`" Type=`"$r/slideMaster`" Target=`"../slideMasters/slideMaster1.xml`"/></Relationships>"
$colors='<a:dk1><a:srgbClr val="4E3440"/></a:dk1><a:lt1><a:srgbClr val="FFFFFF"/></a:lt1><a:dk2><a:srgbClr val="886D78"/></a:dk2><a:lt2><a:srgbClr val="FFF9F6"/></a:lt2><a:accent1><a:srgbClr val="E45288"/></a:accent1><a:accent2><a:srgbClr val="AE3564"/></a:accent2><a:accent3><a:srgbClr val="659381"/></a:accent3><a:accent4><a:srgbClr val="EDB18C"/></a:accent4><a:accent5><a:srgbClr val="E4AAC5"/></a:accent5><a:accent6><a:srgbClr val="FAE7BB"/></a:accent6><a:hlink><a:srgbClr val="AE3564"/></a:hlink><a:folHlink><a:srgbClr val="886D78"/></a:folHlink>'
$fill='<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
$line='<a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>'
Add-Xml 'ppt/theme/theme1.xml' "<a:theme xmlns:a=`"$a`" name=`"Dandori Kitchen`"><a:themeElements><a:clrScheme name=`"Pink`">$colors</a:clrScheme><a:fontScheme name=`"Japanese`"><a:majorFont><a:latin typeface=`"Yu Gothic`"/><a:ea typeface=`"Yu Gothic`"/><a:cs typeface=`"Arial`"/></a:majorFont><a:minorFont><a:latin typeface=`"Yu Gothic`"/><a:ea typeface=`"Yu Gothic`"/><a:cs typeface=`"Arial`"/></a:minorFont></a:fontScheme><a:fmtScheme name=`"Simple`"><a:fillStyleLst>$fill$fill$fill</a:fillStyleLst><a:lnStyleLst>$line$line$line</a:lnStyleLst><a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst><a:bgFillStyleLst>$fill$fill$fill</a:bgFillStyleLst></a:fmtScheme></a:themeElements></a:theme>"
Add-Xml 'docProps/core.xml' '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>Dandori Kitchen - 2026.10.31</dc:title><dc:creator>Maiko Suzuki</dc:creator></cp:coreProperties>'
Add-Xml 'docProps/app.xml' ('<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>Presentation Export</Application><PresentationFormat>On-screen Show (16:9)</PresentationFormat><Slides>'+$slideCount+'</Slides></Properties>')
$zip.Dispose();$file.Dispose()
$checkZip=[IO.Compression.ZipFile]::OpenRead($pptxPath)
$pptxCount=@($checkZip.Entries | Where-Object FullName -match '^ppt/slides/slide\d+\.xml$').Count
$imageCount=@($checkZip.Entries | Where-Object FullName -match '^ppt/media/image\d+\.png$').Count
$checkZip.Dispose()
if($pptxCount -ne $slideCount -or $imageCount -ne $slideCount){throw 'PowerPoint count mismatch'}
@{html=$slideCount;pdf=$pdfCount;powerpoint=$pptxCount;powerpointImages=$imageCount;imageWidth=1600;imageHeight=900} | ConvertTo-Json | Set-Content output/deck/preview/export-check.json -Encoding UTF8
Write-Output "PowerPoint: $pptxCount slides, $imageCount full-slide images"
Eval-JS 'document.documentElement.classList.remove("export");deck.show(0)' | Out-Null
