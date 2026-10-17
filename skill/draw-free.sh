#!/bin/bash
#
# draw-free.sh — 免費 AI 生圖腳本（Pollinations.ai API）macOS / Linux 版
#
# 這是 GitHub mathruffian-dot/opencode-draw-free 的 PowerShell 版
# (draw-free.ps1) 的跨平台移植版，介面與參數完全一致。
#
# 特色：
#   - 100% 免費、開源（Pollinations.ai）
#   - 不需 API Key、不需登入、不需 GPU、不需 Python
#   - 只用 macOS / Linux 內建的 bash 與 curl
#
# 用法：
#   ./draw-free.sh "一隻可愛的水豚在讀書" --name capybara
#   ./draw-free.sh "演講海報" --size 1536x1024 --name poster
#   ./draw-free.sh "四格分鏡" --n 4 --name storyboard
#   ./draw-free.sh "等距視角城市" --model turbo --seed 42 --name city
#
# 參數：
#   prompt（必填）   要畫什麼
#   --size  WxH      預設 1024x1024
#   --model  NAME    預設不指定（自動路由，最快）
#                    flux / zimage / turbo / nanobanana / seedream
#   --seed   N       預設隨機；相同 prompt+seed = 相同圖
#   --n      N       1-8，預設 1
#   --name   NAME    檔名前綴，預設 image
#   --outdir DIR     預設 slides/generated/，沒有 slides/ 則用 ./generated/
#   --delay  SEC     多張時圖片之間的等待秒數（預設 45，配合免費層限制）
#   -h, --help       顯示說明
#
# ⚠️ 免費層限制：同一個對外 IP 每 45 秒只能生 1 張（超過會回 HTTP 402
#    FREE_LIMIT）。多張（--n > 1）時本腳本會自動在圖片之間等待 45 秒。
#    要解除限制可在 https://enter.pollinations.ai 取得 pollen key。
#
# 網址：https://pollinations.ai
#

set -u

# ---------- 參數解析 ----------
PROMPT_PARTS=()
SIZE="1024x1024"
MODEL=""
SEED="-1"
N="1"
NAME="image"
OUTDIR=""
DELAY=""

show_help() {
    # 印出檔頭註解（略過 shebang，遇到第一個非註解行就停）
    awk 'NR==1 { next } /^[^#]/ { exit } { sub(/^# ?/, ""); print }' "$0"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --size)   SIZE="${2:-}"; shift 2 ;;
        --model)  MODEL="${2:-}"; shift 2 ;;
        --seed)   SEED="${2:-}"; shift 2 ;;
        --n)      N="${2:-}"; shift 2 ;;
        --name)   NAME="${2:-}"; shift 2 ;;
        --outdir) OUTDIR="${2:-}"; shift 2 ;;
        --delay)  DELAY="${2:-}"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        --*)      echo "錯誤：未知參數 $1" >&2; exit 1 ;;
        *)        PROMPT_PARTS+=("$1"); shift ;;
    esac
done

# macOS 內建 bash 3.2 沒有 nice 的陣列展開，手動組合
PROMPT_TEXT=""
for part in "${PROMPT_PARTS[@]:-}"; do
    if [ -z "$PROMPT_TEXT" ]; then
        PROMPT_TEXT="$part"
    else
        PROMPT_TEXT="$PROMPT_TEXT $part"
    fi
done
# 去除前後空白
PROMPT_TEXT="$(printf '%s' "$PROMPT_TEXT" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

if [ -z "$PROMPT_TEXT" ]; then
    echo "錯誤：必須提供 prompt 描述" >&2
    echo "用法：$0 \"要畫的內容\" [--size WxH] [--model NAME] [--seed N] [--n N] [--name NAME] [--outdir DIR]" >&2
    exit 1
fi

# 驗證尺寸
if ! printf '%s' "$SIZE" | grep -Eq '^[0-9]+x[0-9]+$'; then
    echo "錯誤：--size 格式應為 WIDTHxHEIGHT，例如 1024x1024" >&2
    exit 1
fi
WIDTH="${SIZE%x*}"
HEIGHT="${SIZE#*x}"

# 驗證張數
if ! printf '%s' "$N" | grep -Eq '^[0-9]+$' || [ "$N" -lt 1 ] || [ "$N" -gt 8 ]; then
    echo "錯誤：--n 必須是 1 到 8 的整數" >&2
    exit 1
fi

# 免費層限制：同一個 IP 每 45 秒只能生 1 張。多張時預設在圖片之間等待。
if [ -z "$DELAY" ]; then
    if [ "$N" -gt 1 ]; then DELAY=45; else DELAY=0; fi
fi
if ! printf '%s' "$DELAY" | grep -Eq '^[0-9]+$'; then
    echo "錯誤：--delay 必須是 0 或正整數（秒）" >&2
    exit 1
fi

# ---------- 決定輸出目錄：--outdir > slides/generated > ./generated ----------
if [ -n "$OUTDIR" ]; then
    OUT_PATH="$OUTDIR"
elif [ -d "slides" ]; then
    OUT_PATH="slides/generated"
else
    OUT_PATH="generated"
fi
mkdir -p "$OUT_PATH" || { echo "錯誤：無法建立輸出目錄 $OUT_PATH" >&2; exit 1; }

STAMP="$(date +%Y%m%d_%H%M%S)"

# ---------- URL 編碼（UTF-8 逐位元組 percent-encode） ----------
urlencode() {
    local s="$1" i c hex out=""
    local n=${#s}
    for ((i=0; i<n; i++)); do
        c="${s:i:1}"
        case "$c" in
            [A-Za-z0-9.~_-]) out+="$c" ;;
            *)
                hex="$(printf '%s' "$c" | od -An -v -tx1 | tr -d ' \n')"
                while [ -n "$hex" ]; do
                    out+="%${hex:0:2}"
                    hex="${hex:2}"
                done
                ;;
        esac
    done
    printf '%s' "$out"
}

# 繁體中文後綴（確保圖中文字為繁中）
TRAD_SUFFIX="，圖片中的所有文字請使用繁體中文（Traditional Chinese）"
FULL_PROMPT="${PROMPT_TEXT}${TRAD_SUFFIX}"
ENCODED_PROMPT="$(urlencode "$FULL_PROMPT")"

# 不指定模型時由服務端自動路由（實測快 15-40 倍）
if [ -n "$MODEL" ]; then
    MODEL_PARAM="&model=${MODEL}"
    MODEL_LABEL="$MODEL"
else
    MODEL_PARAM=""
    MODEL_LABEL="自動"
fi

echo "免費生圖中（Pollinations.ai, ${MODEL_LABEL}, ${WIDTH}x${HEIGHT}, n=${N}）-> $OUT_PATH"
if [ -n "$MODEL" ]; then
    echo "  提示：指定模型會明顯變慢（實測 40 秒以上／張）。不加 --model 最快。"
fi

# ---------- 生成 N 張 ----------
SAVED_FILES=()
SUCCESS_COUNT=0

for ((i=1; i<=N; i++)); do
    # 每張用不同 seed
    if [ "$SEED" -ge 0 ] 2>/dev/null; then
        CURRENT_SEED=$((SEED + i - 1))
    else
        CURRENT_SEED=$(( (RANDOM << 15 | RANDOM) % 999999999 + 1 ))
    fi

    URL="https://image.pollinations.ai/prompt/${ENCODED_PROMPT}?width=${WIDTH}&height=${HEIGHT}${MODEL_PARAM}&seed=${CURRENT_SEED}&nologo=true"

    if [ "$N" -gt 1 ]; then
        SUFFIX="_${i}"
    else
        SUFFIX=""
    fi
    FILE_NAME="${NAME}_${STAMP}${SUFFIX}.png"
    FILE_PATH="${OUT_PATH}/${FILE_NAME}"

    echo "  [$i/$N] 生成中... seed=${CURRENT_SEED}"

    MAX_RETRIES=4
    SUCCESS=0
    for ((retry=1; retry<=MAX_RETRIES; retry++)); do
        HTTP_CODE="$(curl -sS -L --max-time 120 -o "$FILE_PATH" -w '%{http_code}' "$URL" 2>/dev/null)"
        CURL_RC=$?

        if [ "$CURL_RC" -ne 0 ]; then
            if [ "$retry" -lt "$MAX_RETRIES" ]; then
                echo "  [重試 ${retry}/${MAX_RETRIES}] 網路錯誤（curl ${CURL_RC}），等候 3 秒..."
                sleep 3
                continue
            else
                echo "  [FAIL] 第 ${i} 張失敗：網路錯誤（curl ${CURL_RC}）"
                break
            fi
        fi

        FILE_SIZE=0
        if [ -f "$FILE_PATH" ]; then
            FILE_SIZE="$(wc -c < "$FILE_PATH" | tr -d ' ')"
        fi

        # 檔案太小（< 5KB）幾乎一定不是有效圖片，一律重試
        if [ "$FILE_SIZE" -lt 5000 ]; then
            ERR_CONTENT="$(head -c 2000 "$FILE_PATH" 2>/dev/null)"
            WAIT_S=3
            case "$ERR_CONTENT" in
                *FREE_LIMIT*|*"Free limit reached"*)
                    WAIT_S=45 ;;
                *"Queue full"*|*"overloaded"*)
                    WAIT_S=5 ;;
            esac
            # 若訊息有 "Retry after Ns" 就取「兩者較大」的秒數等（避免被過短的建議值拉低）
            PARSED="$(printf '%s' "$ERR_CONTENT" | sed -n 's/.*Retry after \([0-9][0-9]*\)s.*/\1/p')"
            if [ -n "$PARSED" ] && [ "$((PARSED + 2))" -gt "$WAIT_S" ]; then
                WAIT_S=$((PARSED + 2))
            fi
            if [ "$retry" -lt "$MAX_RETRIES" ]; then
                echo "  [重試 ${retry}/${MAX_RETRIES}] HTTP ${HTTP_CODE}（${FILE_SIZE} bytes），等候 ${WAIT_S} 秒..."
                sleep "$WAIT_S"
                continue
            fi
            echo "  [FAIL] 第 ${i} 張失敗：HTTP ${HTTP_CODE}，伺服器持續回傳過小回應"
            break
        fi

        SIZE_KB="$(awk -v b="$FILE_SIZE" 'BEGIN{printf "%.1f", b/1024}')"
        echo "  [OK] $FILE_PATH (${SIZE_KB} KB)"
        SAVED_FILES+=("$FILE_PATH")
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        SUCCESS=1
        break
    done

    if [ "$SUCCESS" -eq 0 ]; then
        # 清掉失敗的空檔
        [ -f "$FILE_PATH" ] && rm -f "$FILE_PATH"
    fi

    # 免費層：每 45 秒 1 張，多張時在圖片之間等待
    if [ "$i" -lt "$N" ] && [ "$DELAY" -gt 0 ]; then
        echo "  （免費層限制：等候 ${DELAY} 秒後再生成下一張）"
        sleep "$DELAY"
    fi
done

echo ""
if [ "$SUCCESS_COUNT" -gt 0 ]; then
    echo "完成！共生成了 ${SUCCESS_COUNT} 張圖片："
    for f in "${SAVED_FILES[@]}"; do
        echo "  $f"
    done
else
    echo "失敗：沒有圖片成功生成"
    exit 1
fi
