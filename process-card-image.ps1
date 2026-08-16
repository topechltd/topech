# ============================================================
# Fullerene additive: replace product photos with 3 new bottle images
# Unified pipeline: 900x900 white canvas, HighQualityBicubic, JPEG q90
#   organic-fullerene-additive.jpg   (overwrite, main image)
#   organic-fullerene-additive-2.jpg (new)
#   organic-fullerene-additive-3.jpg (new)
# ============================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcDir = "C:\Users\33272\AppData\Roaming\QoderCN\SharedClientCache\cache\images\task-ef9"
$outDir = Join-Path $root "images\products"

$files = @(
  @{ s = "fullerene anti wear additive-75515a70.jpg";  d = "organic-fullerene-additive.jpg" },
  @{ s = "fullerene anti wear additive2-5899cf1d.jpg"; d = "organic-fullerene-additive-2.jpg" },
  @{ s = "fullerene anti wear additive3-676f3e1a.jpg"; d = "organic-fullerene-additive-3.jpg" }
)

foreach ($f in $files) {
  $srcPath = Join-Path $srcDir $f.s
  $outPath = Join-Path $outDir $f.d

  $bytes = [System.IO.File]::ReadAllBytes($srcPath)
  $ms = New-Object System.IO.MemoryStream(, $bytes)
  $img = [System.Drawing.Bitmap]::FromStream($ms)

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
  Write-Host ("  [ok] {0} -> {1} (source {2}x{3})" -f $f.s, $f.d, $drawW, $drawH) -ForegroundColor Green
}
Write-Host "All done." -ForegroundColor Yellow
