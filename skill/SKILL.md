---
name: draw-free
description: 免費 AI 生圖技能（Pollinations.ai，全域可用）。當使用者要求「畫一張」「生一張圖」「做一張圖」「產生圖片」但沒有 OpenAI API Key，或明確要求用免費方案生圖時，請使用此技能。此技能呼叫 PowerShell 腳本以 Pollinations.ai 免費 API 生成圖片，不需 API Key、不需登入、不需 GPU、不需安裝 Python，只需 Windows 內建 PowerShell。自動判斷輸出目錄（slides/generated 或 ./generated），支援多張生成、自訂尺寸、模型、隨機種子。適用於無 API Key 的文書筆電教學場景。
---

# 免費生圖技能（Pollinations.ai）

## 用途
以 Pollinations.ai 的免費 URL API 生成圖片。
- 100% 免費、開源
- 不需 API Key、不需登入
- 不需 GPU、不需安裝 Python
- 只需 Windows 內建 PowerShell

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
| Python | 需安裝 + openai 套件 | **不需，用 PowerShell** |
| 模型 | gpt-image-2（頂規） | Flux、Turbo、Nano Banana、Seedream |
| 文字精準度 | 極高（99%） | 中等（複雜中文文字可能出錯） |
| 速度 | 快 | 中等（10-30 秒） |
| 適合場景 | 高品質商用、精準文字 | 教學示意圖、插圖、概念圖、簡報素材 |

**選用原則**：若使用者有 OpenAI Key 且要求高品質 → 用 `draw`；否則用 `draw-free`。

## 前置需求
- Windows 內建 PowerShell（5.1 以上）
- 網路連線
- **不需任何 API Key**
- **不需安裝 Python 或任何套件**

## 腳本位置（Windows）
```
C:\Users\user\.config\opencode\skills\draw-free\draw-free.ps1
```

## 使用方式

### 基本呼叫（PowerShell）
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

### 參數
- `prompt`（必填）：要畫什麼，自然語言描述
- `--size`：`1024x1024`（方，預設）/ `1536x1024`（橫）/ `1024x1536`（直）/ `1920x1080`（橫幅）/ `1080x1920`（直幅）
- `--model`：`flux`（高品質，預設）/ `zimage`（通義 Z-Image-Turbo，中英文文字渲染強）/ `turbo`（快速）/ `nanobanana`（Google）/ `seedream`（字節）
- `--seed`：隨機種子（預設隨機）。相同 prompt + seed = 相同圖片
- `--n`：生成張數 1–8（預設 1）
- `--name`：輸出檔名前綴（預設 `image`）
- `--outdir`：輸出目錄（預設：`slides/generated/`，沒有則用 `./generated/`）

## 全域繁體中文設定
腳本已內建自動附加「繁體中文（Traditional Chinese）」指令到每個提示詞，**不需手動加入**。

注意：Pollinations.ai 對中文文字渲染能力不如 gpt-image-2，若圖中需要精確中文文字（如標題、標籤），建議：
1. 先用 `draw-free` 生成底圖（不含文字或只含簡單文字）
2. 再用其他工具（PowerPoint、Canva、小畫家）疊加中文文字

## 模型選擇原則
- **flux**（預設）：高品質通用，適合插圖、概念圖、簡報素材。
- **zimage**：通義 Z-Image-Turbo（6B 參數），**中英文雙語文字渲染能力最強**，適合需要圖中帶文字的場景。也附帶 2x 超分，畫質更細。
- **turbo**：快速生成（5-10 秒），適合快速預覽、迭代測試。
- **nanobanana**：Google Nano Banana，擅長攝影寫實風格。
- **seedream**：字節跳動模型，對亞洲風格、東方美學較佳。

不確定就用 **flux**；需要圖中文字就用 **zimage**。

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
- **429 Too Many Requests** → Pollinations.ai 免費版有頻率限制，等幾秒再試
- **空白圖 / 違反安全政策** → 改寫 prompt 避開敏感詞

## 費用
**完全免費**。Pollinations.ai 由開源社群維護，不收費、不存資料、匿名使用。

可選：若大量使用，可在 https://enter.pollinations.ai 註冊帳號取得 API Key 以獲得優先頻寬，但**不需要**也能用。
