<#
.SYNOPSIS
  免費生圖腳本（Pollinations.ai API）— 不需 API Key、不需登入、不需 GPU

.DESCRIPTION
  透過 Pollinations.ai 的 URL API 生成圖片。
  100% 免費、開源、零資料儲存。
  只需 Windows 內建的 PowerShell，不需安裝 Python 或任何套件。

.PARAMETER Prompt
  要畫什麼，自然語言描述（必填）。

.PARAMETER Size
  圖片尺寸，格式 WIDTHxHEIGHT（預設：1024x1024）。
  常用：1024x1024（方）、1536x1024（橫）、1024x1536（直）、1920x1080（橫FF）、1080x1920（直FF）

.PARAMETER Model
  AI 模型（預設：不指定，由服務端自動路由——這是最快的走法）。
  選項：flux、turbo、nanobanana（Google Nano Banana）、seedream（字節跳動）

  ⚠️ 實測（2026-07）：明確指定任何模型都會掉到 40 秒以上一張，
  不指定則穩定在 1-3 秒。除非你真的要某個特定模型，否則不要帶這個參數。

.PARAMETER Seed
  隨機種子（預設：隨機）。相同 prompt + seed = 相同圖片，可重現結果。

.PARAMETER N
  生成張數 1-8（預設：1）。每張用不同 seed。

.PARAMETER Name
  輸出檔名前綴（預設：image）。

.PARAMETER OutDir
  輸出目錄（預設：當前工作目錄/slides/generated/，不存在則用 ./generated/）

.EXAMPLE
  .\draw-free.ps1 "一隻可愛的水豚在讀書"
.EXAMPLE
  .\draw-free.ps1 "演講海報，標題寫『AI 教學』" --size 1536x1024 --name poster
.EXAMPLE
  .\draw-free.ps1 "四格分鏡" --n 4 --name storyboard
.EXAMPLE
  .\draw-free.ps1 "等距視角的城市" --model turbo --seed 42 --name city

.NOTES
  網址：https://pollinations.ai
  API：https://image.pollinations.ai/prompt/{描述}?width=W&height=H&seed=S&nologo=true（不帶 model 最快）
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$Prompt,

    [string]$Size = "1024x1024",
    [string]$Model = "",
    [int]$Seed = -1,
    [int]$N = 1,
    [string]$Name = "image",
    [string]$OutDir = $null
)

$ErrorActionPreference = "Stop"

# 合併 prompt（允許多個參數或空格）
$PromptText = ($Prompt -join " ").Trim()

if ([string]::IsNullOrWhiteSpace($PromptText)) {
    Write-Error "錯誤：必須提供 prompt 描述"
    exit 1
}

# 解析尺寸
if ($Size -match "^(\d+)x(\d+)$") {
    $Width = [int]$Matches[1]
    $Height = [int]$Matches[2]
} else {
    Write-Error "錯誤：--size 格式應為 WIDTHxHEIGHT，例如 1024x1024"
    exit 1
}

# 決定輸出目錄：--outdir > slides/generated > ./generated
if ($OutDir) {
    $OutPath = $OutDir
} else {
    $cwd = Get-Location
    $slidesDir = Join-Path $cwd "slides"
    if (Test-Path $slidesDir) {
        $OutPath = Join-Path $slidesDir "generated"
    } else {
        $OutPath = Join-Path $cwd "generated"
    }
}

# 建立輸出目錄
if (-not (Test-Path $OutPath)) {
    New-Item -ItemType Directory -Path $OutPath -Force | Out-Null
}

# 時間戳記
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"

# 繁體中文後綴（確保圖中文字為繁中）
$TradChineseSuffix = "，圖片中的所有文字請使用繁體中文（Traditional Chinese）"
$FullPrompt = $PromptText + $TradChineseSuffix

# URL 編碼
$EncodedPrompt = [uri]::EscapeDataString($FullPrompt)

# 不指定模型時由服務端自動路由（實測快 15-40 倍），指定了才帶 model 參數
$ModelParam = if ([string]::IsNullOrWhiteSpace($Model)) { "" } else { "&model=$Model" }
$ModelLabel = if ([string]::IsNullOrWhiteSpace($Model)) { "自動" } else { $Model }

Write-Host "免費生圖中（Pollinations.ai, $ModelLabel, ${Width}x${Height}, n=$N）-> $OutPath" -ForegroundColor Cyan
if (-not [string]::IsNullOrWhiteSpace($Model)) {
    Write-Host "  提示：指定模型會明顯變慢（實測 40 秒以上／張）。不加 --model 最快。" -ForegroundColor DarkYellow
}

# 生成 N 張
$SavedFiles = @()
for ($i = 1; $i -le $N; $i++) {
    # 每張用不同 seed
    if ($Seed -ge 0) {
        $CurrentSeed = $Seed + ($i - 1)
    } else {
        $CurrentSeed = Get-Random -Minimum 1 -Maximum 999999999
    }

    # 建立 URL
    $Url = "https://image.pollinations.ai/prompt/$EncodedPrompt`?width=$Width&height=$Height$ModelParam&seed=$CurrentSeed&nologo=true"

    # 檔名
    $Suffix = if ($N -gt 1) { "_$i" } else { "" }
    $FileName = "${Name}_${Stamp}${Suffix}.png"
    $FilePath = Join-Path $OutPath $FileName

    Write-Host "  [$i/$N] 生成中... seed=$CurrentSeed" -ForegroundColor Yellow

    $MaxRetries = 4
    $Success = $false
    for ($retry = 1; $retry -le $MaxRetries; $retry++) {
        try {
            $ProgressPreference = "SilentlyContinue"
            Invoke-WebRequest -Uri $Url -OutFile $FilePath -TimeoutSec 120 -ErrorAction Stop
            $ProgressPreference = "Continue"

            $FileInfo = Get-Item $FilePath
            if ($FileInfo.Length -lt 5000) {
                # 檔案太小，可能是錯誤 JSON 回應
                $ErrContent = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
                if ($ErrContent -match "Queue full" -or $ErrContent -match "overloaded") {
                    Write-Host "  [重試 $retry/$MaxRetries] 伺服器佇列已滿，等候 5 秒..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 5
                    continue
                } elseif ($ErrContent -match "error") {
                    Write-Host "  [重試 $retry/$MaxRetries] 伺服器回傳錯誤，等候 3 秒..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 3
                    continue
                }
            }
            $SizeKB = [math]::Round($FileInfo.Length / 1024.0, 1)
            Write-Host "  [OK] $FilePath (${SizeKB} KB)" -ForegroundColor Green
            $SavedFiles += $FilePath
            $Success = $true
            break
        } catch {
            $ProgressPreference = "Continue"
            if ($retry -lt $MaxRetries) {
                Write-Host "  [重試 $retry/$MaxRetries] $($_.Exception.Message)，等候 3 秒..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            } else {
                Write-Host "  [FAIL] 第 $i 張失敗：$($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# 回報結果
if ($SavedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "完成！共生成了 $($SavedFiles.Count) 張圖片：" -ForegroundColor Green
    $SavedFiles | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host ""
    Write-Host "失敗：沒有圖片成功生成" -ForegroundColor Red
    exit 1
}
