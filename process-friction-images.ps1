# ============================================================
# TOPECH static site — friction/anti-wear tester images update
# - Renders (oil friction tester 1-4): unified 900x900 white canvas
# - Real photos: beautified (contrast/brightness) + 900x900 white canvas
# - Copies anti wear test.mp4 -> videos/anti-wear-test.mp4
# Run: powershell -ExecutionPolicy Bypass -File process-friction-images.ps1
# ============================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = "c:\Users\33272\Desktop\电路板\网站\My website\产品图片"
$prodDir = Join-Path $root "images\products"
$videoDir = Join-Path $root "videos"
if (-not (Test-Path $videoDir)) { New-Item -ItemType Directory -Path $videoDir | Out-Null }

function Set-HighQuality($g) {
  $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
}

# source file -> @(target name, beautify?)
$jobs = @(
  @{ s = "oil friction tester 1.jpg";      t = "oil-friction-tester.jpg";           b = $false },
  @{ s = "oil friction tester 2.jpg";      t = "oil-friction-tester-front.jpg";     b = $false },
  @{ s = "oil friction tester 3.jpg";      t = "oil-friction-tester-panel.jpg";     b = $false },
  @{ s = "oil friction tester 4.jpg";      t = "oil-friction-tester-weights.jpg";   b = $false },
  @{ s = "carrying box.jpg";               t = "oil-friction-tester-case.jpg";      b = $true  },
  @{ s = "carrying box2.jpg";              t = "oil-friction-tester-case-2.jpg";    b = $true  },
  @{ s = "carrying box3.jpg";              t = "oil-friction-tester-case-3.jpg";    b = $true  },
  @{ s = "anti weat tester1.jpg";          t = "digital-anti-wear-tester.jpg";      b = $true  },
  @{ s = "portable oil test machine.jpg";  t = "digital-anti-wear-tester-unit.jpg"; b = $true  },
  @{ s = "torque wrench test machine.jpg"; t = "digital-anti-wear-tester-panel.jpg";b = $true  },
  @{ s = "oil anti wear tester.jpg";       t = "digital-anti-wear-tester-set.jpg";  b = $true  }
)

foreach ($j in $jobs) {
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
    } else {
      $g.DrawImage($img, $x, $y, $w, $h)
    }
    $g.Dispose()
    $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]90)
    $bmp.Save($dstPath, $enc, $ep)
    $bmp.Dispose()
    Write-Host "  [ok] $($j.s)  ->  images/products/$($j.t)" -ForegroundColor Green
  } finally { $img.Dispose() }
}

# ---------- video ----------
$vSrc = Join-Path $src "anti wear test.mp4"
$vDst = Join-Path $videoDir "anti-wear-test.mp4"
Copy-Item -Path $vSrc -Destination $vDst -Force
Write-Host "  [ok] anti wear test.mp4 -> videos/anti-wear-test.mp4" -ForegroundColor Green

Write-Host "`nAll done." -ForegroundColor Yellow
