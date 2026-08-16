# ============================================================
# TOPECH static site — five-digit display tester gallery + hero fusion
# 1) 4 new images -> digital-anti-wear-tester gallery (image 1 = main)
# 2) Hero fusion: silver + grey + green + blue machines -> 4:3 hero image
# ============================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = "c:\Users\33272\Desktop\电路板\网站\My website\产品图片"
$prodDir = Join-Path $root "images\products"
$heroDir = Join-Path $root "images\hero"
if (-not (Test-Path $heroDir)) { New-Item -ItemType Directory -Path $heroDir | Out-Null }

function Set-HighQuality($g) {
  $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
}

function Get-JpegEncoder() {
  [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
}

function Get-JpegParams([long]$q) {
  $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $q)
  $ep
}

function Draw-Beautified($g, $img, $rect) {
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
  $g.DrawImage($img, $rect, 0, 0, $img.Width, $img.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
  $ia.Dispose()
}

# ---------- 1) gallery images (900x900 white canvas, real photos beautified) ----------
$gallery = @(
  @{ s = "oil friction test machine.jpg";  t = "digital-anti-wear-tester-silver.jpg";  b = $false },
  @{ s = "oil friction test machine2.jpg"; t = "digital-anti-wear-tester-angle.jpg";   b = $false },
  @{ s = "oil friction test machine3.jpg"; t = "digital-anti-wear-tester-display.jpg"; b = $false },
  @{ s = "oil friction test machine4.jpg"; t = "digital-anti-wear-tester-grey.jpg";    b = $true  }
)

foreach ($j in $gallery) {
  $srcPath = Join-Path $src $j.s
  $dstPath = Join-Path $prodDir $j.t
  $img = [System.Drawing.Bitmap]::FromFile($srcPath)
  try {
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
    if ($j.b) {
      Draw-Beautified $g $img (New-Object System.Drawing.Rectangle $x, $y, $w, $h)
    } else {
      $g.DrawImage($img, $x, $y, $w, $h)
    }
    $g.Dispose()
    $bmp.Save($dstPath, (Get-JpegEncoder), (Get-JpegParams 90))
    $bmp.Dispose()
    Write-Host "  [ok] $($j.s) -> images/products/$($j.t)" -ForegroundColor Green
  } finally { $img.Dispose() }
}

# ---------- 2) hero fusion: 3 machines + additive promo in a 2x2 grid (4:3) ----------
# silver render | grey machine / green machine | engine antifriction promo (cover-fill)
# align: left = flush to cell left edge, right = flush to cell right edge (vertically centered)
$heroSources = @(
  @{ s = "oil friction test machine.jpg"; b = $false; fill = $false; align = "left"  },  # silver (top-left)
  @{ s = "oil friction tester 1.jpg";     b = $false; fill = $false; align = "right" },  # green (top-right)
  @{ s = "engine antifriction promo.jpg"; b = $false; fill = $true;  align = "left"  },  # promo (bottom-left)
  @{ s = "oil friction test machine4.jpg"; b = $true;  fill = $false; align = "right" }   # grey (bottom-right)
)

$W = 1600; $H = 1200; $gap = 16
$cellW = [int](($W - 3 * $gap) / 2)
$cellH = [int](($H - 3 * $gap) / 2)
$hero = New-Object System.Drawing.Bitmap($W, $H)
$hero.SetResolution(72, 72)
$hg = [System.Drawing.Graphics]::FromImage($hero)
Set-HighQuality $hg
$hg.Clear([System.Drawing.Color]::White)

for ($i = 0; $i -lt 4; $i++) {
  $col = $i % 2; $row = [Math]::Floor($i / 2)   # NOTE: [int](1.5) banker's-rounds to 2 in PowerShell!
  $cx = $gap + $col * ($cellW + $gap)
  $cy = $gap + $row * ($cellH + $gap)
  $hs = $heroSources[$i]
  $p = Join-Path $src $hs.s
  # read via MemoryStream to avoid GDI+ file-lock issues (same file used by gallery pass)
  $bytes = [System.IO.File]::ReadAllBytes($p)
  $ms = New-Object System.IO.MemoryStream(, $bytes)
  $img = [System.Drawing.Bitmap]::FromStream($ms)
  try {
    # render each cell into its own bitmap, then composite (avoids graphics-state issues)
    $cell = New-Object System.Drawing.Bitmap($cellW, $cellH)
    $cg = [System.Drawing.Graphics]::FromImage($cell)
    Set-HighQuality $cg
    if ($hs.fill) {
      # cover-fill: promo design fills the whole cell
      $cg.Clear([System.Drawing.Color]::White)
      $scale = [Math]::Max($cellW / $img.Width, $cellH / $img.Height)
      $w = [int]([Math]::Round($img.Width * $scale))
      $h = [int]([Math]::Round($img.Height * $scale))
      $dx = [int](($cellW - $w) / 2); $dy = [int](($cellH - $h) / 2)
      $cg.DrawImage($img, $dx, $dy, $w, $h)
    } else {
      $cg.Clear([System.Drawing.Color]::FromArgb(246, 248, 250))
      $innerPad = 20
      $maxW = $cellW - 2 * $innerPad; $maxH = $cellH - 2 * $innerPad
      $scale = [Math]::Min($maxW / $img.Width, $maxH / $img.Height)
      if ($scale -gt 1) { $scale = 1 }
      $w = [int]([Math]::Round($img.Width * $scale))
      $h = [int]([Math]::Round($img.Height * $scale))
      if ($hs.align -eq "right") {
        $x = $cellW - $innerPad - $w       # flush right
      } else {
        $x = $innerPad                     # flush left
      }
      $y = [int](($cellH - $h) / 2)        # vertically centered
      if ($hs.b) {
        Draw-Beautified $cg $img (New-Object System.Drawing.Rectangle $x, $y, $w, $h)
      } else {
        $cg.DrawImage($img, $x, $y, $w, $h)
      }
      $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(226, 232, 238), 2)
      $cg.DrawRectangle($pen, 0, 0, $cellW - 2, $cellH - 2)
      $pen.Dispose()
    }
    $cg.Dispose()
    # explicit target size avoids dpi-mismatch scaling from DrawImageUnscaled
    $hgx = [System.Drawing.Graphics]::FromImage($hero)
    Set-HighQuality $hgx
    $hgx.DrawImage($cell, $cx, $cy, $cellW, $cellH)
    $hgx.Dispose()
    $cell.Dispose()
    Write-Host "  [ok] hero cell $($i+1): $($hs.s)" -ForegroundColor Green
  } finally { $img.Dispose(); $ms.Dispose() }
}
$hg.Dispose()
$heroPath = Join-Path $heroDir "hero-anti-wear-testers.jpg"
$hero.Save($heroPath, (Get-JpegEncoder), (Get-JpegParams 88))
$hero.Dispose()
Write-Host "  [ok] hero -> images/hero/hero-anti-wear-testers.jpg (1600x1200)" -ForegroundColor Green

Write-Host "`nAll done." -ForegroundColor Yellow
