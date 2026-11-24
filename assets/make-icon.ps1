# Draws the extension icon (VSIX manifest, extensions manager and marketplace listing).
# Concept: a code snippet on a clipboard with an arrow pointing into the target application.
# Output: assets/icon-128.png, assets/icon-256.png, assets/preview-200.png, assets/command-16.png
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

Add-Type -AssemblyName System.Drawing

function New-RoundedPath {
    param([float]$X, [float]$Y, [float]$Width, [float]$Height, [float]$Radius)

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $Radius * 2
    $path.AddArc($X, $Y, $d, $d, 180, 90)
    $path.AddArc($X + $Width - $d, $Y, $d, $d, 270, 90)
    $path.AddArc($X + $Width - $d, $Y + $Height - $d, $d, $d, 0, 90)
    $path.AddArc($X, $Y + $Height - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-NotchPath {
    # Arrow pointing to the right: a bar with a triangular head.
    param([float]$X, [float]$CenterY, [float]$Tail, [float]$HeadBase, [float]$Tip, [float]$Thickness, [float]$HeadHalfHeight)

    $half = $Thickness / 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddPolygon([System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($X, $CenterY - $half),
        [System.Drawing.PointF]::new($HeadBase, $CenterY - $half),
        [System.Drawing.PointF]::new($HeadBase, $CenterY - $HeadHalfHeight),
        [System.Drawing.PointF]::new($Tip, $CenterY),
        [System.Drawing.PointF]::new($HeadBase, $CenterY + $HeadHalfHeight),
        [System.Drawing.PointF]::new($HeadBase, $CenterY + $half),
        [System.Drawing.PointF]::new($X, $CenterY + $half)
    ))
    $path.CloseFigure()
    return $path
}

function New-IconBitmap {
    param([int]$Size = 1024, [bool]$WithArrow = $true)

    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.Clear([System.Drawing.Color]::Transparent)

    $s = [float]$Size / 512.0
    $rect = New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)

    # Tile: diagonal indigo -> violet gradient, same brand colours as earlier releases.
    $tile = New-RoundedPath (16 * $s) (16 * $s) (480 * $s) (480 * $s) (112 * $s)
    $gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(255, 26, 33, 78),
        [System.Drawing.Color]::FromArgb(255, 107, 78, 255),
        45.0)
    $g.FillPath($gradient, $tile)

    # Soft highlight from the top so the tile does not look flat.
    $highlight = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(46, 255, 255, 255),
        [System.Drawing.Color]::FromArgb(0, 255, 255, 255),
        90.0)
    $g.FillPath($highlight, $tile)

    # Clipboard board with a very light tint, so it does not look like a flat white blob.
    $board = New-RoundedPath (120 * $s) (110 * $s) (252 * $s) (280 * $s) (48 * $s)
    $boardBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.RectangleF((120 * $s), (110 * $s), (252 * $s), (280 * $s))),
        [System.Drawing.Color]::FromArgb(255, 255, 255, 255),
        [System.Drawing.Color]::FromArgb(255, 238, 236, 255),
        90.0)
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
    $g.FillPath($boardBrush, $board)

    # Clip at the top of the board: a wide flat bar, so the shape reads as a clipboard
    # and not as a phone with a speaker slit.
    $clip = New-RoundedPath (171 * $s) (86 * $s) (150 * $s) (44 * $s) (18 * $s)
    $clipBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.RectangleF((165 * $s), (82 * $s), (162 * $s), (52 * $s))),
        [System.Drawing.Color]::FromArgb(255, 34, 41, 96),
        [System.Drawing.Color]::FromArgb(255, 78, 58, 210),
        60.0)
    $g.FillPath($clipBrush, $clip)

    # Slot inside the clip.
    $slot = New-RoundedPath (211 * $s) (100 * $s) (70 * $s) (16 * $s) (8 * $s)
    $g.FillPath($white, $slot)

    # </> on the board.
    $font = New-Object System.Drawing.Font("Consolas", (124 * $s), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $textBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.RectangleF((136 * $s), (168 * $s), (224 * $s), (190 * $s))),
        [System.Drawing.Color]::FromArgb(255, 43, 43, 140),
        [System.Drawing.Color]::FromArgb(255, 99, 74, 240),
        35.0)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $textArea = New-Object System.Drawing.RectangleF((118 * $s), (146 * $s), (256 * $s), (208 * $s))
    $g.DrawString("</>", $font, $textBrush, $textArea, $format)

    if ($WithArrow) {
        # Arrow towards the target application.
        $arrow = New-NotchPath (388 * $s) (250 * $s) (0 * $s) (434 * $s) (476 * $s) (30 * $s) (44 * $s)
        $g.FillPath($white, $arrow)
        $arrow.Dispose()
    }

    $format.Dispose()
    $textBrush.Dispose()
    $font.Dispose()
    $slot.Dispose()
    $clipBrush.Dispose()
    $clip.Dispose()
    $boardBrush.Dispose()
    $white.Dispose()
    $board.Dispose()
    $highlight.Dispose()
    $gradient.Dispose()
    $tile.Dispose()
    $g.Dispose()

    return $bitmap
}

function New-CommandIconBitmap {
    param([int]$Size = 16)

    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $s = [float]$Size / 16.0
    $rect = New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)

    $tile = New-RoundedPath 0 0 ([float]$Size) ([float]$Size) (3.6 * $s)
    $gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(255, 32, 40, 104),
        [System.Drawing.Color]::FromArgb(255, 107, 78, 255),
        45.0)
    $g.FillPath($gradient, $tile)

    # Clipboard silhouette: board plus clip, no fine detail that would turn to mush at 16 px.
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $board = New-RoundedPath (3.5 * $s) (3.3 * $s) (9.0 * $s) (9.6 * $s) (1.8 * $s)
    $g.FillPath($white, $board)
    $clip = New-RoundedPath (6.2 * $s) (1.9 * $s) (3.6 * $s) (2.2 * $s) (0.9 * $s)
    $tileBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 58, 50, 168))
    $g.FillPath($tileBrush, $clip)
    $g.FillPath($white, (New-RoundedPath (7.2 * $s) (2.4 * $s) (1.6 * $s) (1.1 * $s) (0.5 * $s)))

    # Slash on the board.
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 70, 52, 196), (1.9 * $s))
    $g.DrawLine($pen, (7.9 * $s), (5.5 * $s), (5.5 * $s), (10.7 * $s))

    $pen.Dispose()
    $tileBrush.Dispose()
    $clip.Dispose()
    $board.Dispose()
    $white.Dispose()
    $gradient.Dispose()
    $tile.Dispose()
    $g.Dispose()

    return $bitmap
}

function Save-Resized {
    param([System.Drawing.Bitmap]$Source, [int]$Size, [string]$Path)

    $target = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($target)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.DrawImage($Source, (New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)))
    $graphics.Dispose()

    $target.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $target.Dispose()
}

$master = New-IconBitmap -Size 1024
$assets = Join-Path $Root "assets"
New-Item -ItemType Directory -Force -Path $assets | Out-Null

Save-Resized -Source $master -Size 256 -Path (Join-Path $assets "icon-256.png")
Save-Resized -Source $master -Size 128 -Path (Join-Path $assets "icon-128.png")
Save-Resized -Source $master -Size 200 -Path (Join-Path $assets "preview-200.png")
$master.Dispose()

$command = New-CommandIconBitmap -Size 16
$command.Save((Join-Path $assets "command-16.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$command.Dispose()

Write-Output ("created: " + (Join-Path $assets "icon-128.png"))
