# ============================================================
# Replace hero with single product image (Oil Anti-Wear Additive)
# Fit into 1600x1200 (4:3) canvas, centered, white background
# Overwrites hero-anti-wear-testers.jpg so no HTML change needed
# ============================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcPath = "C:\Users\33272\AppData\Roaming\QoderCN\SharedClientCache\cache\images\task-ef9\oil anti wear additive 2-405cfdf5.jpg"
$outPath = Join-Path $root "images\hero\hero-anti-wear-testers.jpg"

$img = [System.Drawing.Bitmap]::FromFile($srcPath)
Write-Host "Source: $($img.Width)x$($img.Height)"

$canvasW = 1600; $canvasH = 1200
$pad = 40
$maxW = $canvasW - 2 * $pad; $maxH = $canvasH - 2 * $pad
$scale = [Math]::Min($maxW / $img.Width, $maxH / $img.Height)
if ($scale -gt 1) { $scale = 1 }
$drawW = [int]([Math]::Round($img.Width * $scale))
$drawH = [int]([Math]::Round($img.Height * $scale))

$canvas = New-Object System.Drawing.Bitmap($canvasW, $canvasH)
$canvas.SetResolution(72, 72)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.Clear([System.Drawing.Color]::White)

$x = [int](($canvasW - $drawW) / 2); $y = [int](($canvasH - $drawH) / 2)
$g.DrawImage($img, $x, $y, $drawW, $drawH)
$g.Dispose()
$img.Dispose()

$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]90)
$canvas.Save($outPath, $enc, $ep)
$canvas.Dispose()
Write-Host "Hero saved: $outPath (${canvasW}x${canvasH}), image drawn at ${drawW}x${drawH}" -ForegroundColor Green
