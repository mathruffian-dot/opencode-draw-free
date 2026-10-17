# AGENTS.md — 給 AI Agent 讀的指南

> 本檔案供 OpenCode / Claude Code / Cursor / Codex 等 AI Agent 自動讀取。
> Agent 讀完本檔後，應能立即協助使用者生圖，無需 API Key、無需 GPU。

## 一句話摘要

**`draw-free` 是一個呼叫 Pollinations.ai 免費 URL API 的 AI 生圖技能。零 API Key、零 Python、零 GPU，Windows 用內建 PowerShell、macOS / Linux 用內建 bash 即可使用。**

---

## 何時使用本技能

當使用者說出以下任何一句，且**沒有**明確要求用 OpenAI gpt-image-2：

- 「畫一張 XX」「生一張圖」「做一張圖」「產生圖片」「幫我生圖」
- 「畫個封面／插圖／示意圖／分鏡」
- 「用免費方式生圖」「沒有 API Key 也能生圖嗎」
- 「幫我畫一張，用 Pollinations」

### 選用決策樹

```
使用者要生圖
  ├─ 有 OpenAI API Key + 要求高品質 + 需精準中文字 → 用 draw 技能（gpt-image-2）
  ├─ 沒有 API Key / 想免費 / 文書筆電 / 教學示意圖 → 用 draw-free（本技能）
  └─ 要求完全離線、有強 GPU → 用本地 ComfyUI / Stable Diffusion MCP
```

---

## 技能檔案位置

安裝後的標準路徑（Windows opencode）：
```
C:\Users\user\.config\opencode\skills\draw-free\
  ├─ draw-free.ps1   # 主腳本
  └─ SKILL.md        # OpenCode Skill 設定檔（含 frontmatter）
```

macOS / Linux（opencode）：
```
~/.config/opencode/skills/draw-free/     # 或 ~/.agents/skills/draw-free/
  ├─ draw-free.sh        # 主腳本
  ├─ overlay-text.sh     # 疊字工具（內部用 overlay-text.swift）
  ├─ overlay-text.swift  # 疊字 AppKit 實作
  └─ SKILL.md            # OpenCode Skill 設定檔（含 frontmatter）
```

其他平台可放：
- Claude Code：`~/.claude/skills/draw-free/`
- 通用：任何能執行 PowerShell（Windows）或 bash + curl（macOS / Linux）的路徑

---

## 呼叫方式（給 Agent 的範例）

### 基本生圖
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\skills\draw-free\draw-free.ps1" "A cute capybara reading a book, anime style" --name capybara
```

### 基本生圖（macOS / Linux）
```bash
~/.config/opencode/skills/draw-free/draw-free.sh "A cute capybara reading a book, anime style" --name capybara
```

### 指定尺寸 + 模型 + 種子
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\skills\draw-free\draw-free.ps1" "演講海報" --size 1536x1024 --model flux --seed 42 --name poster
```

### 多張生成
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\skills\draw-free\draw-free.ps1" "四格分鏡" --n 4 --name storyboard
```

### 參數清單
| 參數 | 預設 | 說明 |
|------|------|------|
| `prompt`（必填） | — | 自然語言描述 |
| `--size` | `1024x1024` | `WIDTHxHEIGHT`，常用：1024x1024、1536x1024、1920x1080 |
| `--model` | （不指定＝自動路由，最快） | `flux`/`zimage`/`turbo`/`nanobanana`/`seedream` |
| `--seed` | 隨機 | 整數。相同 prompt+seed=相同圖 |
| `--n` | `1` | 1–8 張 |
| `--name` | `image` | 檔名前綴 |
| `--outdir` | 自動 | 預設 `slides/generated/`，沒有則 `./generated/` |
| `--delay` | `45` | **僅 macOS / Linux 版**：多張時圖片之間的等待秒數 |

---

## 輸出

- 格式：PNG
- 檔名：`<name>_<YYYYMMDD_HHMMSS>.png`，多張加 `_1` `_2`
- 預設目錄：當前工作目錄的 `slides/generated/`（若不存在則建 `./generated/`）

---

## 重要注意事項（Agent 必讀）

### 1. 繁體中文已內建
腳本會自動在 prompt 後加上「圖片中的所有文字請使用繁體中文」。**不要**在 prompt 裡重複加這句。

### 2. 中文文字渲染能力有限
Pollinations.ai（Flux 等）對中文文字渲染**不如 gpt-image-2 精準**。複雜中文字（標題、長句）可能出錯。
- 若使用者需要精準中文字 → 建議「先生底圖（不含文字） → 再用其他工具疊字」
- 本 repo 附帶疊字腳本可在圖上疊對話框中文字（見下方）：Windows 用 `overlay-text.ps1`，macOS / Linux 用 `overlay-text.sh`

### 3. 伺服器偶爾過載／免費層限制
Pollinations.ai 免費版有頻率限制。腳本已內建自動重試 4 次。若仍失敗：
- 等 30 秒再試
- 換 `--model turbo`（較快、較少過載）
- 或建議使用者到 https://enter.pollinations.ai 註冊免費帳號取得 API Key（可选）

> ⚠️ **2026-10 實測**：免費匿名層是**同一個對外 IP 每 45 秒只能生 1 張**，超過
> 會回 **HTTP 402 FREE_LIMIT**（舊說明寫的 429「queue full」已不準）。
> `draw-free.sh`（macOS / Linux）會偵測 402 並自動等 45 秒後重試；`--n > 1` 時
> 也會自動在圖片之間等 45 秒（`--delay SEC` 可調整）。

### 4. 品質等級
本技能無 `--quality` 參數（Pollinations.ai 免費版不支援）。品質由模型決定：
- **預設不要帶 `--model`**（自動路由約 1 秒；指定任何模型都慢 15–40 倍）。需要特定風格才指定：
- `flux`：高品質通用
- `turbo`：快速（5-10 秒，適合預覽）
- `nanobanana`：攝影寫實風
- `zimage`：中英文文字渲染最強
- `seedream`：亞洲風格、東方美學

### 5. 費用
**完全免費**。Pollinations.ai 開源社群維護，不收費、不存資料、匿名使用。

---

## 加值工具：overlay-text（文字疊加）

本 repo 附帶文字疊加腳本，可在生成的圖片上加上對話框與中文字。Windows 用
`overlay-text.ps1`（System.Drawing），macOS / Linux 用 `overlay-text.sh`
（內部呼叫 `overlay-text.swift`，AppKit 實作，首次執行自動用 `swiftc` 編譯快取）。

### 用法（Windows）
```powershell
powershell -ExecutionPolicy Bypass -File overlay-text.ps1 `
  -SrcPath "generated/capybara.png" `
  -DstPath "generated/capybara_final.png" `
  -Text "壓力？那能吃嗎？" `
  -Subtitle "— 卡皮巴拉的人生哲學"
```

### 用法（macOS / Linux）
```bash
overlay-text.sh \
  --src generated/capybara.png --dst generated/capybara_final.png \
  --text "壓力？那能吃嗎？" --subtitle "— 卡皮巴拉的人生哲學"
```

### 功能
- 白底黑框圓角對話框（置中偏上）
- 三角形尾巴指向主體
- 主文字（Windows：微軟正黑體 42pt 粗體；macOS：PingFang TC 42pt 粗體）
- 底部半透明副標

### 限制
- 字型：Windows 用 `Microsoft JhengHei`、macOS 用 `PingFang TC`（皆系統內建，無需安裝）
- 對話框位置固定（置中偏上），若需調整需改腳本
- macOS 版需要 `swift` / `swiftc`（Xcode Command Line Tools；多數開發機已有）

---

## 安裝方式（給 Agent 協助安裝時）

### 方法 1：複製到 opencode skills（推薦）
```powershell
# 建立目錄
New-Item -ItemType Directory -Path "$env:USERPROFILE\.config\opencode\skills\draw-free" -Force

# 複製兩個檔案
Copy-Item "draw-free.ps1" "$env:USERPROFILE\.config\opencode\skills\draw-free\"
Copy-Item "SKILL.md" "$env:USERPROFILE\.config\opencode\skills\draw-free\"
```

### 方法 2：Claude Code
```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\skills\draw-free" -Force
Copy-Item "draw-free.ps1" "$env:USERPROFILE\.claude\skills\draw-free\"
Copy-Item "SKILL.md" "$env:USERPROFILE\.claude\skills\draw-free\"
```

### 方法 3：macOS / Linux（bash）
```bash
mkdir -p ~/.config/opencode/skills/draw-free
cp skill/draw-free.sh skill/SKILL.md ~/.config/opencode/skills/draw-free/
cp overlay-text.sh overlay-text.swift ~/.config/opencode/skills/draw-free/
chmod +x ~/.config/opencode/skills/draw-free/*.sh
```

### 確認安裝
```powershell
Test-Path "$env:USERPROFILE\.config\opencode\skills\draw-free\draw-free.ps1"
```
```bash
# macOS / Linux
test -x ~/.config/opencode/skills/draw-free/draw-free.sh && echo OK
```

---

## 與其他方案的比較（供 Agent 推薦時參考）

| 方案 | 費用 | API Key | Python | GPU | 中文文字 | 適合 |
|------|------|---------|--------|-----|---------|------|
| **draw-free（本技能）** | 免費 | 不用 | 不用 | 不用 | 中等 | 教學、示意圖、插圖 |
| draw（OpenAI gpt-image-2） | NT$0.3-5.5/張 | 需 | 需 | 不用 | 極高 | 商用、精準文字 |
| Pollinations MCP Server | 免費 | 可選 | 不用 | 不用 | 中等 | 想要 MCP 原生整合 |
| Puter.js | 免費 | 不用 | 不用 | 不用 | 高 | 網頁前端生圖 |
| fal.ai MCP | NT$1/張 | 需 | 不用 | 不用 | 視模型 | 多模型、最快 |
| 本地 ComfyUI | 免費 | 不用 | 需 | 需 | 視模型 | 完全離線 |

---

## 疑難排解

| 症狀 | 原因 | 解決 |
|------|------|------|
| HTTP 402 FREE_LIMIT | 免費層同 IP 每 45 秒 1 張 | `draw-free.sh` 會自動等 45 秒重試；或稍候再試 |
| HTTP 500 / 429 Queue full | 伺服器過載 | 腳本會自動重試；或等 30 秒再試 |
| 檔案 < 5KB | 回傳了錯誤 JSON | 換 model 或改 prompt |
| 中文亂碼 | PowerShell 讀檔編碼問題 | 確認 .ps1 是 UTF-8 with BOM |
| 圖中中文文字錯亂 | Flux 模型中文能力有限 | 用 overlay-text（Windows `.ps1` / macOS `.sh`）疊字 |
| macOS 找不到 swift | 未裝 Xcode Command Line Tools | 執行 `xcode-select --install` |

---

## 來源與授權

- 生圖 API：[Pollinations.ai](https://pollinations.ai)（MIT 授權，開源）
- 本技能腳本：MIT 授權
- 作者：mathruffian-dot
