# Android 12+ can animate its system splash icon before Flutter's first frame.
# Trace the same bundled Noto Sans wordmark used by the static launch artwork.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$appRoot = Split-Path -Parent $PSScriptRoot
$fontPath = Join-Path $appRoot 'assets/fonts/NotoSans-Regular.ttf'
$drawable = Join-Path $appRoot 'android/app/src/main/res/drawable-v31'
$animator = Join-Path $appRoot 'android/app/src/main/res/animator'
New-Item -ItemType Directory -Path $drawable, $animator -Force | Out-Null

function Number([double]$value) {
    return $value.ToString('0.###', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Point([System.Drawing.PointF]$value) {
    $x = 216 + ($value.X - 300) * 0.575
    $y = 216 + ($value.Y - 150) * 0.575
    return "$(Number $x),$(Number $y)"
}

function PathData([System.Drawing.Drawing2D.GraphicsPath]$shape) {
    $result = [System.Text.StringBuilder]::new()
    $points = $shape.PathPoints
    $types = $shape.PathTypes
    $i = 0
    while ($i -lt $points.Length) {
        $kind = $types[$i] -band 7
        if ($kind -eq 0) {
            [void]$result.Append("M$(Point $points[$i]) ")
            if (($types[$i] -band 128) -ne 0) { [void]$result.Append('Z ') }
            $i++
        } elseif ($kind -eq 1) {
            [void]$result.Append("L$(Point $points[$i]) ")
            if (($types[$i] -band 128) -ne 0) { [void]$result.Append('Z ') }
            $i++
        } elseif ($kind -eq 3 -and $i + 2 -lt $points.Length) {
            [void]$result.Append("C$(Point $points[$i]) $(Point $points[$i + 1]) $(Point $points[$i + 2]) ")
            if (($types[$i + 2] -band 128) -ne 0) { [void]$result.Append('Z ') }
            $i += 3
        } else {
            throw "Unexpected font path segment at ${i}: $kind"
        }
    }
    return $result.ToString().Trim()
}

$fonts = [System.Drawing.Text.PrivateFontCollection]::new()
$fonts.AddFontFile($fontPath)
$wordmark = [System.Drawing.Drawing2D.GraphicsPath]::new()
$format = [System.Drawing.StringFormat]::GenericDefault.Clone()
try {
    $format.FormatFlags = $format.FormatFlags -bor [System.Drawing.StringFormatFlags]::NoWrap
    $wordmark.AddString('AstraCue', $fonts.Families[0],
        [int][System.Drawing.FontStyle]::Regular, 96,
        [System.Drawing.PointF]::new(0, 0), $format)
    $bounds = $wordmark.GetBounds()
    $translation = [System.Drawing.Drawing2D.Matrix]::new()
    try {
        $translation.Translate((600 - $bounds.Width) / 2 - $bounds.X, 93 - $bounds.Y)
        $wordmark.Transform($translation)
    } finally {
        $translation.Dispose()
    }
    $wordmarkData = PathData $wordmark
} finally {
    $format.Dispose()
    $wordmark.Dispose()
    $fonts.Dispose()
}

$starShape = [System.Drawing.Drawing2D.GraphicsPath]::new()
try {
    $starShape.StartFigure()
    $starShape.AddBezier([System.Drawing.PointF]::new(300, 18), [System.Drawing.PointF]::new(304, 33),
        [System.Drawing.PointF]::new(309, 38), [System.Drawing.PointF]::new(324, 43))
    $starShape.AddBezier([System.Drawing.PointF]::new(324, 43), [System.Drawing.PointF]::new(309, 48),
        [System.Drawing.PointF]::new(304, 53), [System.Drawing.PointF]::new(300, 68))
    $starShape.AddBezier([System.Drawing.PointF]::new(300, 68), [System.Drawing.PointF]::new(296, 53),
        [System.Drawing.PointF]::new(291, 48), [System.Drawing.PointF]::new(276, 43))
    $starShape.AddBezier([System.Drawing.PointF]::new(276, 43), [System.Drawing.PointF]::new(291, 38),
        [System.Drawing.PointF]::new(296, 33), [System.Drawing.PointF]::new(300, 18))
    $starShape.CloseFigure()
    $starData = PathData $starShape
} finally {
    $starShape.Dispose()
}

function CircleData([double]$centerX, [double]$centerY, [double]$radius) {
    $diameter = 2 * $radius
    return "M$(Number ($centerX - $radius)),$(Number $centerY) a$(Number $radius),$(Number $radius) 0 1,0 $(Number $diameter),0 a$(Number $radius),$(Number $radius) 0 1,0 -$(Number $diameter),0"
}

$orbitCenterX = 216
$orbitCenterY = 277
$orbitRadius = 23
$orbitRing = CircleData $orbitCenterX $orbitCenterY $orbitRadius
$orbitDots = @(0..2 | ForEach-Object {
    $angle = $_ * [math]::PI * 2 / 3
    $x = $orbitCenterX + [math]::Cos($angle) * $orbitRadius
    $y = $orbitCenterY + [math]::Sin($angle) * $orbitRadius
    CircleData $x $y $(if ($_ -eq 0) { 6.5 } else { 5.5 })
})
$vector = @"
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="432dp" android:height="432dp"
    android:viewportWidth="432" android:viewportHeight="432">
    <path android:fillColor="#00000000" android:strokeColor="#224EB3E8"
        android:strokeWidth="8" android:fillType="evenOdd"
        android:pathData="$wordmarkData" />
    <path android:fillColor="#00000000" android:strokeColor="#20D8B66A"
        android:strokeWidth="5" android:fillType="evenOdd"
        android:pathData="$wordmarkData" />
    <path android:fillType="evenOdd" android:pathData="$wordmarkData">
        <aapt:attr name="android:fillColor">
            <gradient android:type="linear" android:startX="90" android:startY="210"
                android:endX="342" android:endY="210">
                <item android:offset="0" android:color="#BFDDF1" />
                <item android:offset="0.48" android:color="#F4F7FC" />
                <item android:offset="1" android:color="#E7CB8D" />
            </gradient>
        </aapt:attr>
    </path>
    <path android:strokeColor="#30D8B66A" android:strokeWidth="1.5"
        android:pathData="$starData">
        <aapt:attr name="android:fillColor">
            <gradient android:type="linear" android:startX="216" android:startY="140"
                android:endX="216" android:endY="169">
                <item android:offset="0" android:color="#F1D486" />
                <item android:offset="1" android:color="#C49B54" />
            </gradient>
        </aapt:attr>
    </path>
    <group android:name="orbit_dots" />
</vector>
"@

$animated = @'
<?xml version="1.0" encoding="utf-8"?>
<animated-vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:drawable="@drawable/launch_wordmark_vector">
    <target android:name="orbit_dots" android:animation="@animator/launch_orbit" />
</animated-vector>
'@

$rotation = @'
<?xml version="1.0" encoding="utf-8"?>
<objectAnimator xmlns:android="http://schemas.android.com/apk/res/android"
    android:propertyName="rotation" android:duration="2400"
    android:repeatCount="infinite" android:repeatMode="restart"
    android:valueFrom="0" android:valueTo="360" android:valueType="floatType"
    android:interpolator="@android:interpolator/linear" />
'@

$encoding = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $drawable 'launch_wordmark_vector.xml'), $vector.Trim() + "`n", $encoding)
[System.IO.File]::WriteAllText((Join-Path $drawable 'launch_wordmark_animated.xml'), $animated.Trim() + "`n", $encoding)
[System.IO.File]::WriteAllText((Join-Path $animator 'launch_orbit.xml'), $rotation.Trim() + "`n", $encoding)
Write-Output 'Generated Android 12+ animated splash vector.'
