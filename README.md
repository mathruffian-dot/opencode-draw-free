# draw-free — 免費 AI 生圖技能 for OpenCode / Claude Code

> 零 API Key、零 Python、零 GPU。只要 Windows 內建 PowerShell 就能生圖。

## 這是什麼

一個用 PowerShell 呼叫 [Pollinations.ai](https://pollinations.ai) 免費 URL API 的 AI 生圖技能，專為沒有 OpenAI API Key、沒有獨顯的文書筆電設計。

## 特色

- **完全免費** — Pollinations.ai 開源社群維護
- **不需 API Key、不需登入**
- **不需安裝 Python** — 只用 Windows 內建 PowerShell
- **不需 GPU** — 運算在雲端
- **支援多模型** — Flux、Turbo、Nano Banana、Seedream
- **自動重試** — 伺服器過載時自動重試 4 次
- **繁中內建** — 自動附加繁體中文提示
- **多張生成** — 一次 1-8 張

## 快速開始

### 1. 安裝

把 `skill/` 資料夾裡的兩個檔案複製到你的 skills 目錄：

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

### 2. 生圖

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\skills\draw-free\draw-free.ps1" "A cute capybara reading a book, anime style" --name capybara
```

圖片會存到當前工作目錄的 `slides/generated/`（沒有則建 `./generated/`）。

### 3. 加對話框（可选）

```powershell
powershell -ExecutionPolicy Bypass -File overlay-text.ps1 `
  -SrcPath "generated/capybara.png" `
  -DstPath "generated/capybara_final.png" `
  -Text "壓力？那能吃嗎？" `
  -Subtitle "— 卡皮巴拉的人生哲學"
```

## 參數

| 參數 | 預設 | 說明 |
|------|------|------|
| `prompt`（必填） | — | 要畫什麼 |
| `--size` | `1024x1024` | `WIDTHxHEIGHT` |
| `--model` | `flux` | `flux`/`turbo`/`nanobanana`/`seedream` |
| `--seed` | 隨機 | 相同 prompt+seed=相同圖 |
| `--n` | `1` | 1–8 張 |
| `--name` | `image` | 檔名前綴 |
| `--outdir` | 自動 | 預設 `slides/generated/` |

## 模型選擇

| 模型 | 特色 | 適合 |
|------|------|------|
| `flux` | 高品質通用（預設） | 插圖、概念圖、簡報素材 |
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

- 中文文字渲染不如 gpt-image-2 精準（建議先生底圖再疊字）
- 免費版有頻率限制（腳本會自動重試）
- 需網路連線

## 檔案結構

```
draw-free-pkg/
├── skill/
│   ├── draw-free.ps1    # 主生圖腳本
│   └── SKILL.md         # OpenCode Skill 設定檔
├── overlay-text.ps1     # 對話框文字疊加腳本
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
