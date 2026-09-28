# Regenerate launcher icons from the supplied artwork on Windows.
# Run from any directory: powershell -File mobile_app/tool/generate_app_icons.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$appRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $appRoot 'assets/branding/yes_no_source.png'
$androidRes = Join-Path $appRoot 'android/app/src/main/res'
$iosIconSet = Join-Path $appRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$source = [System.Drawing.Bitmap]::FromFile($sourcePath)

try {
    if ($source.Width -ne $source.Height) {
        throw 'Launcher icon source must be square.'
    }

    # The original image has a transparent 4px fringe at its top and left.
    # A tiny even crop removes it without changing the artwork composition.
    $edgeCrop = 5
    $cropSize = $source.Width - 2 * $edgeCrop
    $background = [System.Drawing.Color]::FromArgb(2, 3, 9)

    function Write-Icon([string]$path, [int]$size) {
        $bitmap = [System.Drawing.Bitmap]::new(
            $size, $size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
        )
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear($background)
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.DrawImage(
                    $source,
                    [System.Drawing.Rectangle]::new(0, 0, $size, $size),
                    [System.Drawing.Rectangle]::new($edgeCrop, $edgeCrop, $cropSize, $cropSize),
                    [System.Drawing.GraphicsUnit]::Pixel
                )
            } finally {
                $graphics.Dispose()
            }
            $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $bitmap.Dispose()
        }
    }

    $androidSizes = [ordered]@{
        mdpi = 48
        hdpi = 72
        xhdpi = 96
        xxhdpi = 144
        xxxhdpi = 192
    }
    foreach ($density in $androidSizes.Keys) {
        Write-Icon (Join-Path $androidRes "mipmap-$density/ic_launcher.png") $androidSizes[$density]
    }

    $catalog = Get-Content (Join-Path $iosIconSet 'Contents.json') -Raw | ConvertFrom-Json
    $generated = @{}
    foreach ($icon in $catalog.images) {
        if ($generated.ContainsKey($icon.filename)) { continue }
        $points = [double]($icon.size.Split('x')[0])
        $scale = [int]($icon.scale.TrimEnd('x'))
        $pixels = [int][Math]::Round($points * $scale)
        Write-Icon (Join-Path $iosIconSet $icon.filename) $pixels
        $generated[$icon.filename] = $true
    }

    Write-Output "Generated $($androidSizes.Count) Android and $($generated.Count) iOS launcher icons."
} finally {
    $source.Dispose()
}
