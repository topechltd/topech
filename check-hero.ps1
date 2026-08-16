Add-Type -AssemblyName System.Drawing
$src = "C:\Users\33272\AppData\Roaming\QoderCN\SharedClientCache\cache\images\task-ef9\anti wear additive-39d01ca1.jpg"
$bmp = [System.Drawing.Bitmap]::FromFile($src)
"size: $($bmp.Width)x$($bmp.Height)"

# crop extreme bottom-right corner for visual inspection
$root = "c:\Users\33272\Desktop\电路板\网站\My website\TOPECH Nano-web"
$rect = New-Object System.Drawing.Rectangle 1350, 1180, 356, 99
$crop = $bmp.Clone($rect, $bmp.PixelFormat)
$cropPath = Join-Path $root "images\hero\_debug-corner.jpg"
$crop.Save($cropPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
"saved corner crop (src coords x=1350..1706, y=1180..1279)"
$crop.Dispose()
$bmp.Dispose()
