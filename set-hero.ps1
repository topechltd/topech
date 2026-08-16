Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

$root = "c:\Users\33272\Desktop\电路板\网站\My website\TOPECH Nano-web"
$src = "C:\Users\33272\AppData\Roaming\QoderCN\SharedClientCache\cache\images\task-ef9\oil anti wear additive 2-405cfdf5.jpg"

$bytes = [System.IO.File]::ReadAllBytes($src)
$ms = New-Object System.IO.MemoryStream(, $bytes)
$img = [System.Drawing.Bitmap]::FromStream($ms)
"source: $($img.Width)x$($img.Height)  ratio=$([Math]::Round($img.Width / $img.Height, 4))"

# hero target: 4:3 (hero-figure uses aspect-ratio 4/3), output 1600x1200
$TW = 1600; $TH = 1200
$targetRatio = $TW / $TH
$srcRatio = $img.Width / $img.Height

# center-crop to 4:3 if needed
if ([Math]::Abs($srcRatio - $targetRatio) -lt 0.01) {
  $sx = 0; $sy = 0; $sw = $img.Width; $sh = $img.Height
} elseif ($srcRatio -gt $targetRatio) {
  $sh = $img.Height; $sw = [int]($img.Height * $targetRatio)
  $sx = [int](($img.Width - $sw) / 2); $sy = 0
} else {
  $sw = $img.Width; $sh = [int]($img.Width / $targetRatio)
  $sx = 0; $sy = [int](($img.Height - $sh) / 2)
}
"crop region: x=$sx y=$sy ${sw}x$sh"

$hero = New-Object System.Drawing.Bitmap($TW, $TH)
$hero.SetResolution(72, 72)
$g = [System.Drawing.Graphics]::FromImage($hero)
$g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.DrawImage($img, 0, 0, (New-Object System.Drawing.Rectangle $sx, $sy, $sw, $sh), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$img.Dispose()
$ms.Dispose()

$out = Join-Path $root "images\hero\hero-anti-wear-testers.jpg"
$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]90)
$hero.Save($out, $enc, $ep)
$hero.Dispose()
"saved: $out (1600x1200)"

# clean up debug files
Get-ChildItem (Join-Path $root "images\hero") -Filter "_debug*" | ForEach-Object {
  Remove-Item $_.FullName -Force
  "removed: $($_.Name)"
}
"All done."
