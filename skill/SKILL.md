---
name: draw-free
description: 免費 AI 生圖技能（Pollinations.ai，跨平台）。當使用者要求「畫一張」「生一張圖」「做一張圖」「產生圖片」但沒有 OpenAI API Key，或明確要求用免費方案生圖時，請使用此技能。呼叫腳本以 Pollinations.ai 免費 API 生成圖片，不需 API Key、不需登入、不需 GPU、不需安裝 Python。Windows 用 draw-free.ps1（內建 PowerShell），macOS / Linux 用 draw-free.sh（bash + curl）。自動判斷輸出目錄（slides/generated 或 ./generated），支援多張生成、自訂尺寸、模型、隨機種子，並自動處理免費層每 45 秒 1 張的 402 限制。適用於無 API Key 的文書筆電教學場景。
---

# 免費生圖技能（Pollinations.ai）

## 用途
以 Pollinations.ai 的免費 URL API 生成圖片。
- 100% 免費、開源
- 不需 API Key、不需登入
- 不需 GPU、不需安裝 Python
- Windows 用內建 PowerShell；macOS / Linux 用內建 bash + curl

## 觸發情境
使用者說出：
- 「畫一張 XX」「生一張圖」「做一張圖」「產生圖片」「幫我生圖」
- 「畫個封面／插圖／示意圖／分鏡」
- 「用免費方式生圖」「沒有 API Key 也能生圖嗎」
- 「幫我畫一張，用 Pollinations」

## 與 `draw` 技能的差異
| 項目 | `draw`（OpenAI gpt-image-2） | `draw-free`（Pollinations.ai） |
|------|------------------------------|-------------------------------|
| 費用 | 約 NT$0.3-5.5/張 | **完全免費** |
| API Key | 需 OpenAI Key + 組織驗證 | **不需任何 Key** |
| Python | 需安裝 + openai 套件 | **不需，用系統內建工具** |
| 模型 | gpt-image-2（頂規） | Flux、Turbo、Nano Banana、Seedream |
| 文字精準度 | 極高（99%） | 中等（複雜中文文字可能出錯） |
| 速度 | 快 | 中等（10-30 秒） |
| 適合場景 | 高品質商用、精準文字 | 教學示意圖、插圖、概念圖、簡報素材 |

**選用原則**：若使用者有 OpenAI Key 且要求高品質 → 用 `draw`；否則用 `draw-free`。

## 前置需求
- Windows 內建 PowerShell（5.1 以上）**或** macOS / Linux 的 bash + curl
- 網路連線
- **不需任何 API Key**
- **不需安裝 Python 或任何套件**

> **平台**：Windows 用 `draw-free.ps1`；macOS / Linux 用同目錄的
> `draw-free.sh`，介面與參數完全一致（另多一個 `--delay`）。
> 疊字工具同理：Windows 用 `overlay-text.ps1`，macOS 用 `overlay-text.sh`
> （內部呼叫 `overlay-text.swift`，用 macOS 內建 AppKit，不需任何套件）。

## 腳本位置

安裝後放在你的 skills 目錄：

Windows：
```
$env:USERPROFILE\.config\opencode\skills\draw-free\
  ├─ draw-free.ps1
  └─ overlay-text.ps1
```

macOS / Linux：
```
~/.config/opencode/skills/draw-free/        # 或 ~/.agents/skills/draw-free/
  ├─ draw-free.sh
  ├─ overlay-text.sh        # 疊字工具（內部用 overlay-text.swift）
  └─ overlay-text.swift
```

## 使用方式

### 基本呼叫（Windows PowerShell）
```powershell
# 基本生圖
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\skills\draw-free\draw-free.ps1" "要畫的內容"

# 指定尺寸、檔名
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\skills\draw-free\draw-free.ps1" "演講海報" --size 1536x1024 --name poster

# 多張生成
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\skills\draw-free\draw-free.ps1" "四格分鏡" --n 4 --name storyboard

# 指定模型與種子（可重現）
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\skills\draw-free\draw-free.ps1" "等距視角城市" --model turbo --seed 42 --name city
```

### 基本呼叫（macOS / Linux）
```bash
# 基本生圖
~/.config/opencode/skills/draw-free/draw-free.sh "一隻可愛的水豚在讀書"

# 指定尺寸、檔名
~/.config/opencode/skills/draw-free/draw-free.sh "演講海報" --size 1536x1024 --name poster

# 多張生成（免費層每 45 秒 1 張，腳本會自動在圖片之間等待）
~/.config/opencode/skills/draw-free/draw-free.sh "四格分鏡" --n 4 --name storyboard

# 指定模型與種子（可重現）
~/.config/opencode/skills/draw-free/draw-free.sh "等距視角城市" --model turbo --seed 42 --name city
```

### 參數
- `prompt`（必填）：要畫什麼，自然語言描述
- `--size`：`1024x1024`（方，預設）/ `1536x1024`（橫）/ `1024x1536`（直）/ `1920x1080`（橫幅）/ `1080x1920`（直幅）
- `--model`：**預設不指定（自動路由，最快）**。可選 `flux` / `zimage` / `turbo` / `nanobanana` / `seedream`。
  ⚠️ **實測指定任何模型都會慢 15–40 倍**（不指定 1.3 秒 vs 指定 21–45 秒），非必要不要帶。
- `--seed`：隨機種子（預設隨機）。相同 prompt + seed = 相同圖片
- `--n`：生成張數 1–8（預設 1）
- `--name`：輸出檔名前綴（預設 `image`）
- `--outdir`：輸出目錄（預設：`slides/generated/`，沒有則用 `./generated/`）
- `--delay SEC`：**僅 macOS / Linux 版**。多張時圖片之間的等待秒數（預設 45）

### macOS / Linux 疊字工具（overlay-text.sh）

在圖片上加上對話框與中文字（白底黑框圓角對話框 + 底部半透明副標）：

```bash
~/.config/opencode/skills/draw-free/overlay-text.sh \
  --src generated/base.png --dst generated/final.png \
  --text "壓力？那能吃嗎？" --subtitle "— 卡皮巴拉的人生哲學"
```

首次執行會自動用 `swiftc` 編譯 `overlay-text.swift` 並快取到
`$TMPDIR/draw-free-overlay/`，之後直接執行快取檔；若沒有 `swiftc` 則退回
`swift` 直譯模式。字型自動挑選 PingFang TC / Heiti TC，無需安裝任何套件。

## 圖中要有文字時：一律走後製，不要交給生圖模型

**這類模型畫不出正確的中文字。** 實測「練太久了」四個字會生成六個形似漢字、但實際不存在的字；英文也常有錯字（`TOO MUCH PRACTICE` → `TOO MOUCH PRACTVE`）。

**正確流程**：
1. 用 `draw-free` 生「**不含任何文字**」的底圖
2. 用同 repo 的疊字腳本把文字疊上去（Windows：`overlay-text.ps1`；macOS：`overlay-text.sh`）（或用 PowerPoint／Canva）

腳本雖然會自動附加「繁體中文」指令，**但那只影響模型的風格傾向，不會讓它把字寫對**。要精確文字就用後製。

## 🔴 免費層流量限制（2026-10 實測已變更）

免費匿名層的限制是**同一個對外 IP 每 45 秒只能生 1 張**。超過時伺服器回
**HTTP 402**，內容為：

```json
{"status":402,"success":false,"error":{"code":"FREE_LIMIT",
 "message":"Free limit reached: 1 image every 45 seconds per IP. Retry after 20s, ..."}}
```

（較舊的說明寫「同時只准 1 個請求、回 429」，請以 402 FREE_LIMIT 為準。）

影響與對策：
- 一個人自己慢慢用 → 沒問題
- **多張生成（`--n`）或連續生圖** → 會被擋。`draw-free.sh` 已內建因應：
  - 偵測到 402 FREE_LIMIT 時，自動等待 **45 秒**再重試（取伺服器建議秒數與
    45 秒的較大值）
  - `--n > 1` 時，自動在圖片之間等待 45 秒（可用 `--delay 0` 關閉或調整）
- 教室／辦公室共用同一個對外 IP → 大家會互相卡
- 要解除限制可在 https://enter.pollinations.ai 取得 pollen key（非必要）

> 註：Pollinations 回傳的是 **JPEG** 位元組，即使檔名存成 `.png`；這點與
> 原 PowerShell 版行為相同。

## 模型選擇原則

**預設不要帶 `--model`。** 實測不指定是 1.3 秒，指定任何模型都掉到 21–45 秒；而且中文提示詞下，指定 `flux` 的構圖遵循度並沒有比較好。

以下只在你確定要某個特定風格時才用：
- **flux**：高品質通用，適合插圖、概念圖、簡報素材。
- **zimage**：通義 Z-Image-Turbo（6B 參數），**中英文雙語文字渲染能力最強**，適合需要圖中帶文字的場景。也附帶 2x 超分，畫質更細。
- **turbo**：快速生成（5-10 秒），適合快速預覽、迭代測試。
- **nanobanana**：Google Nano Banana，擅長攝影寫實風格。
- **seedream**：字節跳動模型，對亞洲風格、東方美學較佳。

**不確定就不要帶 `--model`**（最快）。需要圖中有精確文字 → 不是換模型能解決的，請走後製疊字。

## 尺寸建議
| 用途 | 尺寸 |
|------|------|
| 簡報插圖（4:3） | `1024x1024` 或 `1536x1024` |
| 簡報全幅（16:9） | `1920x1080` |
| 海報（直） | `1024x1536` |
| 社群貼文 | `1080x1080` |
| YouTube 封面 | `1280x720` |

## 輸出
PNG 檔，檔名格式：`<name>_<YYYYMMDD_HHMMSS>.png`，多張時加 `_1` `_2` 後綴。

## 錯誤處理
- **網路逾時** → 預設 timeout 120 秒；Flux 模型可能需 10-30 秒，複雜 prompt 更久
- **檔案過小** → 腳本會警告（可能回傳了錯誤訊息而非圖片）
- **HTTP 402 FREE_LIMIT** → 免費層每 45 秒 1 張；`draw-free.sh` 會自動等 45 秒後重試
- **HTTP 429 Too Many Requests** → 頻率限制，等幾秒再試
- **空白圖 / 違反安全政策** → 改寫 prompt 避開敏感詞

## 費用
**完全免費**。Pollinations.ai 由開源社群維護，不收費、不存資料、匿名使用。

可選：若大量使用，可在 https://enter.pollinations.ai 註冊帳號取得 API Key 以獲得優先頻寬，但**不需要**也能用。
