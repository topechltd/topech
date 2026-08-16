# ============================================================
# Process nano-graphene additive promo as new gallery main image
# Unified pipeline: 900x900 white canvas, HighQualityBicubic, JPEG q90
# Output: images/products/nano-graphene-additive-promo.jpg
# ============================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcPath = "C:\Users\33272\AppData\Roaming\QoderCN\SharedClientCache\cache\images\task-ef9\engine antifriction promo-47f1c88d.jpg"
$outPath = Join-Path $root "images\products\nano-graphene-additive-promo.jpg"

$bytes = [System.IO.File]::ReadAllBytes($srcPath)
$ms = New-Object System.IO.MemoryStream(, $bytes)
$img = [System.Drawing.Bitmap]::FromStream($ms)
Write-Host "Source: $($img.Width)x$($img.Height)"

$canvasSize = 900; $pad = 30
$maxW = $canvasSize - 2 * $pad; $maxH = $canvasSize - 2 * $pad
$scale = [Math]::Min($maxW / $img.Width, $maxH / $img.Height)
$drawW = [int]([Math]::Round($img.Width * $scale))
$drawH = [int]([Math]::Round($img.Height * $scale))

$canvas = New-Object System.Drawing.Bitmap($canvasSize, $canvasSize)
$canvas.SetResolution(72, 72)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.Clear([System.Drawing.Color]::White)

$posX = [int](($canvasSize - $drawW) / 2); $posY = [int](($canvasSize - $drawH) / 2)
$g.DrawImage($img, $posX, $posY, $drawW, $drawH)
$g.Dispose()
$img.Dispose()
$ms.Dispose()

$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]90)
$canvas.Save($outPath, $enc, $ep)
$canvas.Dispose()
Write-Host "Saved: $outPath (${canvasSize}x${canvasSize})" -ForegroundColor Green
