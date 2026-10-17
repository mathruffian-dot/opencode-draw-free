# draw-free — 免費 AI 生圖技能 for OpenCode / Claude Code

> 零 API Key、零 Python、零 GPU。Windows 用內建 PowerShell、macOS / Linux 用內建 bash，就能生圖。

## 這是什麼

一個用 [Pollinations.ai](https://pollinations.ai) 免費 URL API 生圖的 AI 生圖技能，專為沒有 OpenAI API Key、沒有獨顯的文書筆電設計。Windows 走 PowerShell，macOS / Linux 走 bash + curl。

## 特色

- **完全免費** — Pollinations.ai 開源社群維護
- **不需 API Key、不需登入**
- **不需安裝 Python** — Windows 只用內建 PowerShell；macOS / Linux 只用內建 bash + curl
- **跨平台** — Windows / macOS / Linux 皆有原生腳本
- **不需 GPU** — 運算在雲端
- **支援多模型** — Flux、Turbo、Nano Banana、Seedream
- **自動重試** — 伺服器過載時自動重試 4 次
- **繁中內建** — 自動附加繁體中文提示
- **多張生成** — 一次 1-8 張

## 快速開始

### 1. 安裝

把 `skill/` 資料夾裡的檔案複製到你的 skills 目錄：

**Windows（PowerShell）**

```powershell
# OpenCode
New-Item -ItemType Directory -Path "$env:USERPROFILE\.config\opencode\skills\draw-free" -Force
Copy-Item "skill\draw-free.ps1" "$env:USERPROFILE\.config\opencode\skills\draw-free\"
Copy-Item "skill\SKILL.md" "$env:USERPROFILE\.config\opencode\skills\draw-free\"

# Claude Code
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\skills\draw-free" -Force
Copy-Item "skill\draw-free.ps1" "$env:USERPROFILE\.claude\skills\draw-free\"
Copy-Item "skill\SKILL.md" "$env:USERPROFILE\.claude\skills\draw-free\"
```

**macOS / Linux（bash）**

```bash
# OpenCode（~/.config/opencode/skills 或 ~/.agents/skills 皆可）
mkdir -p ~/.config/opencode/skills/draw-free
cp skill/draw-free.sh skill/SKILL.md ~/.config/opencode/skills/draw-free/
cp overlay-text.sh overlay-text.swift ~/.config/opencode/skills/draw-free/
chmod +x ~/.config/opencode/skills/draw-free/*.sh
```

### 2. 生圖

**Windows**

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\skills\draw-free\draw-free.ps1" "A cute capybara reading a book, anime style" --name capybara
```

**macOS / Linux**

```bash
~/.config/opencode/skills/draw-free/draw-free.sh "A cute capybara reading a book, anime style" --name capybara
```

圖片會存到當前工作目錄的 `slides/generated/`（沒有則建 `./generated/`）。

### 3. 加對話框（可选）

**Windows**

```powershell
powershell -ExecutionPolicy Bypass -File overlay-text.ps1 `
  -SrcPath "generated/capybara.png" `
  -DstPath "generated/capybara_final.png" `
  -Text "壓力？那能吃嗎？" `
  -Subtitle "— 卡皮巴拉的人生哲學"
```

**macOS / Linux**（首次執行會自動用 `swiftc` 編譯並快取）

```bash
~/.config/opencode/skills/draw-free/overlay-text.sh \
  --src generated/capybara.png --dst generated/capybara_final.png \
  --text "壓力？那能吃嗎？" --subtitle "— 卡皮巴拉的人生哲學"
```

## 參數

| 參數 | 預設 | 說明 |
|------|------|------|
| `prompt`（必填） | — | 要畫什麼 |
| `--size` | `1024x1024` | `WIDTHxHEIGHT` |
| `--model` | **不指定（自動）** | `flux`/`turbo`/`nanobanana`/`seedream`。**建議不要帶**，見下方速度說明 |
| `--seed` | 隨機 | 相同 prompt+seed=相同圖 |
| `--n` | `1` | 1–8 張 |
| `--name` | `image` | 檔名前綴 |
| `--outdir` | 自動 | 預設 `slides/generated/` |
| `--delay` | `45` | **僅 macOS / Linux 版**：多張時圖片之間的等待秒數 |

## 模型選擇

> ⚠️ **2026-07 實測：不指定模型最快，快 15–40 倍。**
> 同一句提示詞、避開快取的量測結果：不指定 **1.3 秒**／`flux` **21.6–45.4 秒**／`zimage` 44.9 秒／`turbo` 44.8 秒。
> 而且用中文提示詞時，指定 `flux` 的**構圖遵循度並沒有比較好**（兩者同樣會漏掉指定的物件）。
> **除非你真的要某個特定模型，否則不要帶 `--model`。**

| 模型 | 特色 | 適合 |
|------|------|------|
| （不指定） | **預設，最快** | 絕大多數情況 |
| `flux` | 高品質通用 | 需要特定風格時 |
| `zimage` | 通義 Z-Image-Turbo，**中英文文字渲染最強** | 圖中帶文字、海報 |
| `turbo` | 快速 5-10 秒 | 預覽、迭代 |
| `nanobanana` | 攝影寫實 | 寫實風格 |
| `seedream` | 東方美學 | 亞洲風格 |

## 與其他方案比較

| 方案 | 費用 | API Key | Python | 中文文字 |
|------|------|---------|--------|---------|
| **draw-free** | 免費 | 不用 | 不用 | 中等 |
| draw (gpt-image-2) | NT$0.3-5.5/張 | 需 | 需 | 極高 |
| Pollinations MCP | 免費 | 可選 | 不用 | 中等 |
| fal.ai MCP | NT$1/張 | 需 | 不用 | 視模型 |
| 本地 ComfyUI | 免費 | 不用 | 需 | 視模型 |

## 限制

### 🔴 匿名層「同一個 IP 同時只准 1 個請求」

實測伺服器回應：

```
HTTP 429  Queue full for IP: xxx: 1 requests already queued (max: 1)  "tier":"anonymous"
```

意思是**同一個對外 IP 底下，同時只有一個請求能進行**。兩個請求同時送，一個成功、一個直接被擋。

**影響**：一個人自己用完全沒問題；但**一整間教室、一個辦公室共用同一個對外 IP 的情境不適用**——大家同時生圖會互相卡。腳本雖然會自動重試（最多 4 次、每次等 5 秒），人多時仍會失敗。

### ❌ 圖中文字：中文不要指望，英文也不可靠

這一類擴散模型畫不出正確的中文字——**生出來的是形似漢字但查無此字的東西**。英文也常有錯字。

**正解是後製**：先用本技能生「不含文字的底圖」，再用 `overlay-text.ps1`（Windows）或 `overlay-text.sh`（macOS）把文字疊上去。文字要正確就不要交給生圖模型。

### 其他

- 需網路連線
- 中文提示詞的構圖遵循度普通（複雜場景容易漏掉指定物件，建議拆成簡單句或改用英文提示詞）

## 檔案結構

```
draw-free-pkg/
├── skill/
│   ├── draw-free.ps1    # 主生圖腳本（Windows PowerShell）
│   ├── draw-free.sh     # 主生圖腳本（macOS / Linux bash）
│   └── SKILL.md         # OpenCode Skill 設定檔（跨平台）
├── overlay-text.ps1     # 對話框文字疊加腳本（Windows）
├── overlay-text.sh      # 對話框文字疊加腳本（macOS / Linux 包裝）
├── overlay-text.swift   # 對話框文字疊加（macOS AppKit 實作）
├── AGENTS.md            # 給 AI Agent 讀的詳細指南
├── README.md            # 本檔
└── LICENSE              # MIT
```

## 授權

MIT License — 自由使用、修改、散布。

## 感謝

- [Pollinations.ai](https://pollinations.ai) — 免費開源生圖 API
- [opencode](https://opencode.ai) — 開源 AI coding agent

## 相關連結

- Pollinations.ai 官網：https://pollinations.ai
- Pollinations API 文件：https://gen.pollinations.ai/docs
- Pollinations MCP Server：`npx @pollinations/mcp`
