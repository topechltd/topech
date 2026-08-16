# Re-save all .ps1 scripts as UTF-8 with BOM (required by Windows PowerShell 5.1)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Get-ChildItem -Path $root -Filter *.ps1 | Where-Object { $_.Name -ne "add-bom.ps1" } | ForEach-Object {
  $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
  [System.IO.File]::WriteAllText($_.FullName, $text, (New-Object System.Text.UTF8Encoding($true)))
  Write-Host "BOM added: $($_.Name)"
}
