# ============================================================
# TOPECH static site — image download & processing script
# 1) Downloads product images from topechltd.com
# 2) Unifies sizes: product images -> 900x900 white canvas (contain, centered)
#    hero image -> max width 1200
# 3) Generates favicon.png
# Run: powershell -ExecutionPolicy Bypass -File download-images.ps1
# ============================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$rawDir  = Join-Path $root "images\raw"
$prodDir = Join-Path $root "images\products"
$heroDir = Join-Path $root "images\hero"
foreach ($d in @($rawDir, $prodDir, $heroDir)) {
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

# ---------- download helper (tries each candidate url) ----------
function Get-Image($candidates, $destRaw) {
  if (Test-Path $destRaw) { Write-Host "  [skip] already downloaded: $(Split-Path $destRaw -Leaf)"; return $true }
  foreach ($u in $candidates) {
    try {
      $enc = [uri]::EscapeUriString($u)
      Invoke-WebRequest -Uri $enc -OutFile $destRaw -UserAgent $ua -UseBasicParsing -TimeoutSec 60 | Out-Null
      if ((Test-Path $destRaw) -and (Get-Item $destRaw).Length -gt 1000) {
        Write-Host "  [ok] $u"
        return $true
      }
    } catch {
      Write-Host "  [retry] $u  ->  $($_.Exception.Message)"
    }
  }
  Write-Host "  [FAIL] all candidates failed for $(Split-Path $destRaw -Leaf)" -ForegroundColor Red
  return $false
}

# ---------- resize helpers ----------
function Set-HighQuality($g) {
  $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
}

# Product image: contain into 900x900 white square canvas, centered
function Convert-ProductImage($srcPath, $dstPath) {
  $src = [System.Drawing.Bitmap]::FromFile($srcPath)
  try {
    $canvas = 900
    $pad = 45
    $maxW = $canvas - 2 * $pad; $maxH = $canvas - 2 * $pad
    $scale = [Math]::Min($maxW / $src.Width, $maxH / $src.Height)
    if ($scale -gt 1) { $scale = 1 }
    $w = [int]([Math]::Round($src.Width * $scale))
    $h = [int]([Math]::Round($src.Height * $scale))
    $bmp = New-Object System.Drawing.Bitmap($canvas, $canvas)
    $bmp.SetResolution(72, 72)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    Set-HighQuality $g
    $g.Clear([System.Drawing.Color]::White)
    $x = [int](($canvas - $w) / 2); $y = [int](($canvas - $h) / 2)
    $g.DrawImage($src, $x, $y, $w, $h)
    $g.Dispose()
    if ($dstPath -match "\.png$") {
      $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } else {
      $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
      $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
      $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]88)
      $bmp.Save($dstPath, $enc, $ep)
    }
    $bmp.Dispose()
  } finally { $src.Dispose() }
}

# Hero image: resize to max width 1200, keep ratio
function Convert-HeroImage($srcPath, $dstPath) {
  $src = [System.Drawing.Bitmap]::FromFile($srcPath)
  try {
    $maxW = 1200
    $scale = [Math]::Min(1, $maxW / $src.Width)
    $w = [int]([Math]::Round($src.Width * $scale))
    $h = [int]([Math]::Round($src.Height * $scale))
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    Set-HighQuality $g
    $g.DrawImage($src, 0, 0, $w, $h)
    $g.Dispose()
    $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]85)
    $bmp.Save($dstPath, $enc, $ep)
    $bmp.Dispose()
  } finally { $src.Dispose() }
}

# ---------- image manifest: target name -> candidate urls ----------
$base = "https://topechltd.com/wp-content/uploads"
$images = @(
  @{ name = "oil-friction-tester.jpg";            urls = @("$base/2012/01/new-oil-friction-tester.jpg") },
  @{ name = "oil-abrasion-test-machine.jpg";      urls = @("$base/2012/01/oil-abrasion-test-machine.jpg") },
  @{ name = "friction-tester-weights.png";        urls = @("$base/2017/04/weights-300x215.png", "$base/2017/04/weights.png") },
  @{ name = "digital-anti-wear-tester.jpg";       urls = @("$base/2012/11/IMG_3003.jpg", "$base/2012/01/new-oil-friction-tester.jpg") },
  @{ name = "anti-wear-tester-display.jpg";       urls = @("$base/2018/08/TIM图片20180626144844.jpg", "$base/2018/05/TIM图片20171021121206.jpg", "$base/2012/01/oil-abrasion-test-machine.jpg") },
  @{ name = "high-temp-engine-oil-tester.jpg";    urls = @("$base/2019/06/TIM图片20181024143103-2-576x1024.jpg") },
  @{ name = "high-temp-oil-test-tube.jpg";        urls = @("$base/2019/06/TIM图片20181024143038-1.jpg") },
  @{ name = "high-temp-oil-test-result.jpg";      urls = @("$base/2019/06/IMG_3530-1024x768.jpg", "$base/2019/06/IMG_3532-1.jpg") },
  @{ name = "flash-point-tester.jpg";             urls = @("$base/2017/04/flash-point-apparatus.jpg", "$base/2017/04/flash-point-apparatus-300x300.jpg") },
  @{ name = "kinematic-viscosity-tester-lyv8.jpg";urls = @("$base/2017/04/viscosity_-e1493739259468.jpg") },
  @{ name = "kinematic-viscosity-tester-ly445.jpg";urls = @("$base/2017/04/kinematic-viscosity-tester-2.jpg", "$base/2017/04/kinematic-viscosity-tester-2-300x300.jpg") },
  @{ name = "pour-point-tester.jpg";              urls = @("$base/2017/05/pour-point-tester.jpg") },
  @{ name = "oil-acidity-analyzer.jpg";           urls = @("$base/2017/05/20131107144935559.jpg") },
  @{ name = "karl-fischer-water-content-tester.png"; urls = @("$base/2017/04/moi.png") },
  @{ name = "petroleum-density-tester.jpg";       urls = @("$base/2017/05/Petroleum-products-density-test-equipment.jpg") },
  @{ name = "oil-color-chroma-tester.png";        urls = @("$base/2017/04/LY-041-e1493735707752.png") },
  @{ name = "oil-color-wheel.png";                urls = @("$base/2012/01/oil-color.png") },
  @{ name = "copper-strip-corrosion-tester.png";  urls = @("$base/2017/04/copper-corrosion-tester.png") },
  @{ name = "copper-strip-corrosion-bath-lpg.jpg";urls = @("$base/2017/04/copper-strip-corrosion-test-for-LPG.jpg") },
  @{ name = "nano-graphene-additive.jpg";         urls = @("$base/2020/05/IMG_20200530_225635-1-969x1024.jpg") },
  @{ name = "nano-graphene-additive-2.jpg";       urls = @("$base/2020/05/1.jpg") },
  @{ name = "nano-graphene-additive-3.jpg";       urls = @("$base/2020/05/2-1.jpg") },
  @{ name = "organic-fullerene-additive.jpg";     urls = @("$base/2020/03/0C2C8C1F69C28E390E85393E621C01B5-1024x485.jpg") },
  @{ name = "fullerene-friction-chart-1.png";     urls = @("$base/2019/05/图片1-1.png") },
  @{ name = "fullerene-friction-chart-2.png";     urls = @("$base/2019/05/图片3.png") },
  @{ name = "fullerene-friction-chart-3.png";     urls = @("$base/2019/05/图片5.png") },
  @{ name = "nano-anti-wear-additive.jpg";        urls = @("$base/2017/09/Anti-friction-nano-oils-additive.jpg") },
  @{ name = "nano-anti-wear-additive-2.png";      urls = @("$base/2017/09/anti-friction-additive.png") },
  @{ name = "nano-anti-wear-additive-3.jpg";      urls = @("$base/2017/09/TIM图片20170829101251.jpg") },
  @{ name = "metal-anti-wear-repair-agent.jpg";   urls = @("$base/2018/01/1308285143.jpg") },
  @{ name = "boride-ep-drilling-lubricant.png";   urls = @("$base/2019/07/钻井LY-3010.png") },
  @{ name = "engine-oil-system-cleaner.jpg";      urls = @("$base/2022/03/IMG_20220310_151402-scaled.jpg", "$base/2022/03/IMG_20220310_151402.jpg") }
)

Write-Host "`n===== Downloading product images =====" -ForegroundColor Cyan
$ok = 0; $fail = 0
foreach ($it in $images) {
  $ext = [System.IO.Path]::GetExtension($it.name)
  $destRaw = Join-Path $rawDir $it.name
  if (Get-Image $it.urls $destRaw) {
    try {
      Convert-ProductImage $destRaw (Join-Path $prodDir $it.name)
      Write-Host "  [processed] $($it.name)" -ForegroundColor Green
      $ok++
    } catch {
      Write-Host "  [process-FAIL] $($it.name): $($_.Exception.Message)" -ForegroundColor Red
      $fail++
    }
  } else { $fail++ }
}

Write-Host "`n===== Hero image =====" -ForegroundColor Cyan
$heroRaw = Join-Path $rawDir "hero-friction-tester.jpg"
if (Get-Image @("$base/2017/04/chinese-supplier-oil-friction-tester-e1493738501630.jpg") $heroRaw) {
  Convert-HeroImage $heroRaw (Join-Path $heroDir "hero-friction-tester.jpg")
  Write-Host "  [processed] hero-friction-tester.jpg" -ForegroundColor Green
}

# ---------- favicon ----------
Write-Host "`n===== Generating favicon =====" -ForegroundColor Cyan
$fv = New-Object System.Drawing.Bitmap(64, 64)
$g = [System.Drawing.Graphics]::FromImage($fv)
Set-HighQuality $g
$g.Clear([System.Drawing.Color]::FromArgb(11, 61, 102))
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$font = New-Object System.Drawing.Font("Arial", 38, [System.Drawing.FontStyle]::Bold)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center
$rect = New-Object System.Drawing.RectangleF(0, 0, 64, 64)
$g.DrawString("T", $font, $brush, $rect, $sf)
$g.Dispose()
$fv.Save((Join-Path $root "images\favicon.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$fv.Dispose()
Write-Host "  [ok] images/favicon.png" -ForegroundColor Green

Write-Host "`nDone. success=$ok, failed=$fail" -ForegroundColor Yellow
