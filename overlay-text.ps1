<#
.SYNOPSIS
  在圖片上加上對話框與中文字（PowerShell System.Drawing 版）
#>

param(
    [Parameter(Mandatory = $true)][string]$SrcPath,
    [Parameter(Mandatory = $true)][string]$DstPath,
    [string]$Text = "壓力？那能吃嗎？",
    [string]$Subtitle = "— 卡皮巴拉的人生哲學"
)

Add-Type -AssemblyName System.Drawing

# 載入原圖
$img = [System.Drawing.Image]::FromFile($SrcPath)
$bmp = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# 先畫原圖
$g.DrawImage($img, 0, 0, $img.Width, $img.Height)
$img.Dispose()

[int]$W = $bmp.Width
[int]$H = $bmp.Height

# === 對話框設定 ===
[int]$bubbleW = 560
[int]$bubbleH = 160
[int]$bubbleX = [int][math]::Floor(($W - $bubbleW) / 2)
[int]$bubbleY = 60
[int]$radius = 30

# 白色填充 + 黑色邊框
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$blackPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 5.0)

# 圓角矩形路徑
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
[int]$r2 = $radius * 2
$path.AddArc([float]$bubbleX, [float]$bubbleY, [float]$r2, [float]$r2, 180.0, 90.0)
$path.AddArc([float]($bubbleX + $bubbleW - $r2), [float]$bubbleY, [float]$r2, [float]$r2, 270.0, 90.0)
$path.AddArc([float]($bubbleX + $bubbleW - $r2), [float]($bubbleY + $bubbleH - $r2), [float]$r2, [float]$r2, 0.0, 90.0)
$path.AddArc([float]$bubbleX, [float]($bubbleY + $bubbleH - $r2), [float]$r2, [float]$r2, 90.0, 90.0)
$path.CloseFigure()

$g.FillPath($whiteBrush, $path)
$g.DrawPath($blackPen, $path)

# 對話框尾巴（三角形指向水豚）
[int]$tailStart = $bubbleX + 180
[float]$tx1 = [float]$tailStart
[float]$ty1 = [float]($bubbleY + $bubbleH)
[float]$tx2 = [float]($tailStart - 50)
[float]$ty2 = [float]($bubbleY + $bubbleH + 70)
[float]$tx3 = [float]($tailStart + 80)
[float]$ty3 = [float]($bubbleY + $bubbleH)

# 填充三角形（蓋住底部邊框線）
$tailPts = New-Object 'System.Drawing.PointF[]' 3
$tailPts[0] = (New-Object System.Drawing.PointF($tx1, $ty1))
$tailPts[1] = (New-Object System.Drawing.PointF($tx2, $ty2))
$tailPts[2] = (New-Object System.Drawing.PointF($tx3, $ty3))
$g.FillPolygon($whiteBrush, $tailPts)

# 尾框（只畫兩側）
$g.DrawLine($blackPen, $tx1, $ty1, $tx2, $ty2)
$g.DrawLine($blackPen, $tx2, $ty2, $tx3, $ty3)

# === 主文字 ===
$fontMain = New-Object System.Drawing.Font("Microsoft JhengHei", 42.0, [System.Drawing.FontStyle]::Bold)
$textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 60, 60))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center

[float]$rx = [float]($bubbleX + 10)
[float]$ry = [float]($bubbleY + 10)
[float]$rw = [float]($bubbleW - 20)
[float]$rh = [float]($bubbleH - 20)
$rectMain = New-Object System.Drawing.RectangleF($rx, $ry, $rw, $rh)
$g.DrawString($Text, $fontMain, $textBrush, $rectMain, $sf)

# === 底部副標 ===
if ($Subtitle) {
    $fontSub = New-Object System.Drawing.Font("Microsoft JhengHei", 22.0, [System.Drawing.FontStyle]::Regular)
    $subBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255))
    $subBgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(120, 0, 0, 0))

    $subSize = $g.MeasureString($Subtitle, $fontSub)
    [int]$subW = [int]$subSize.Width + 30
    [int]$subH = [int]$subSize.Height + 10
    [int]$subX = [int][math]::Floor(($W - $subW) / 2)
    [int]$subY = $H - $subH - 30

    [float]$srx = [float]$subX
    [float]$sry = [float]$subY
    [float]$srw = [float]$subW
    [float]$srh = [float]$subH
    $subRect = New-Object System.Drawing.RectangleF($srx, $sry, $srw, $srh)

    $subPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    [int]$sr = 12
    [int]$sr2 = $sr * 2
    $subPath.AddArc([float]$subX, [float]$subY, [float]$sr2, [float]$sr2, 180.0, 90.0)
    $subPath.AddArc([float]($subX + $subW - $sr2), [float]$subY, [float]$sr2, [float]$sr2, 270.0, 90.0)
    $subPath.AddArc([float]($subX + $subW - $sr2), [float]($subY + $subH - $sr2), [float]$sr2, [float]$sr2, 0.0, 90.0)
    $subPath.AddArc([float]$subX, [float]($subY + $subH - $sr2), [float]$sr2, [float]$sr2, 90.0, 90.0)
    $subPath.CloseFigure()
    $g.FillPath($subBgBrush, $subPath)

    $sfSub = New-Object System.Drawing.StringFormat
    $sfSub.Alignment = [System.Drawing.StringAlignment]::Center
    $sfSub.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString($Subtitle, $fontSub, $subBrush, $subRect, $sfSub)
}

# 儲存
$bmp.Save($DstPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

Write-Host "[OK] 已加上對話框：$DstPath" -ForegroundColor Green
