# ============================================================
# TOPECH static site — high-temp engine oil tester image refresh
# Same pipeline as anti-wear testers:
#   beautify (contrast 1.12 / brightness +0.03) + 900x900 white canvas
# Overwrites existing files in images/products (same names -> pages update automatically)
# ============================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$prodDir = Join-Path $root "images\products"

function Set-HighQuality($g) {
  $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
}

$files = @(
  "high-temp-engine-oil-tester.jpg",
  "high-temp-oil-test-tube.jpg",
  "high-temp-oil-test-result.jpg"
)

foreach ($f in $files) {
  $path = Join-Path $prodDir $f
  if (-not (Test-Path $path)) { Write-Host "  [skip] $f not found" -ForegroundColor Yellow; continue }

  # read via stream so the file handle is released before overwrite
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $ms = New-Object System.IO.MemoryStream(, $bytes)
  $img = [System.Drawing.Bitmap]::FromStream($ms)
  Write-Host ("  [info] {0}  {1}x{2}" -f $f, $img.Width, $img.Height)

  $canvas = 900; $pad = 45
  $maxW = $canvas - 2 * $pad; $maxH = $canvas - 2 * $pad
  $scale = [Math]::Min($maxW / $img.Width, $maxH / $img.Height)
  if ($scale -gt 1) { $scale = 1 }
  $w = [int]([Math]::Round($img.Width * $scale))
  $h = [int]([Math]::Round($img.Height * $scale))

  $bmp = New-Object System.Drawing.Bitmap($canvas, $canvas)
  $bmp.SetResolution(72, 72)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  Set-HighQuality $g
  $g.Clear([System.Drawing.Color]::White)
  $x = [int](($canvas - $w) / 2); $y = [int](($canvas - $h) / 2)

  # beautify: contrast 1.12 around midpoint + brightness lift 0.03
  $c = [float]1.12; $off = [float](0.5 * (1 - 1.12) + 0.03)
  $cmArr = New-Object 'float[][]' 5
  $cmArr[0] = [float[]]@($c, 0, 0, 0, 0)
  $cmArr[1] = [float[]]@(0, $c, 0, 0, 0)
  $cmArr[2] = [float[]]@(0, 0, $c, 0, 0)
  $cmArr[3] = [float[]]@(0, 0, 0, 1, 0)
  $cmArr[4] = [float[]]@($off, $off, $off, 0, 1)
  $cm = New-Object System.Drawing.Imaging.ColorMatrix(, $cmArr)
  $ia = New-Object System.Drawing.Imaging.ImageAttributes
  $ia.SetColorMatrix($cm)
  $g.DrawImage($img, (New-Object System.Drawing.Rectangle $x, $y, $w, $h), 0, 0, $img.Width, $img.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
  $ia.Dispose()
  $g.Dispose()
  $img.Dispose()
  $ms.Dispose()

  $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
  $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]90)
  $bmp.Save($path, $enc, $ep)
  $bmp.Dispose()
  Write-Host "  [ok] $f beautified + unified 900x900" -ForegroundColor Green
}

Write-Host "`nAll done." -ForegroundColor Yellow
