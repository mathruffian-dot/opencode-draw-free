#!/bin/bash
#
# overlay-text.sh — 在圖片上加上對話框與中文字（macOS 原生版）
#
# 這是 overlay-text.ps1（Windows / System.Drawing 版）的 macOS 版包裝。
# 內部使用 AppKit 繪圖（透過 overlay-text.swift），不需要安裝任何套件
# （不需 Python、不需 Pillow、不需 ImageMagick）。
#
# 首次執行會用 swiftc 編譯一次並快取，之後直接執行快取的執行檔。
#
# 用法：
#   overlay-text.sh --src 原圖.png --dst 輸出.png
#   overlay-text.sh --src 原圖.png --dst 輸出.png --text "壓力？那能吃嗎？" \
#                   --subtitle "— 卡皮巴拉的人生哲學"
#   overlay-text.sh 原圖.png 輸出.png          # 也可用位置參數
#
# 參數：
#   --src,  -SrcPath    來源圖片（必填）
#   --dst,  -DstPath    輸出 PNG（必填）
#   --text, -Text       對話框主文字（預設：壓力？那能吃嗎？）
#   --subtitle, -Subtitle  底部副標（預設：— 卡皮巴拉的人生哲學；給 "" 則不畫）
#   --font NAME         指定字型（預設自動挑選繁中字型）
#   --main-size N       主文字大小（預設 42）
#   --sub-size  N       副標大小（預設 22）
#   --bubble-w / --bubble-h  對話框寬/高（預設 560 / 160）
#   -h, --help          顯示說明
#
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SWIFT_SRC="$SCRIPT_DIR/overlay-text.swift"

if [ ! -f "$SWIFT_SRC" ]; then
    echo "[錯誤] 找不到 $SWIFT_SRC" >&2
    exit 1
fi

# ------- 取得 swift 執行方式：優先編譯快取，其次直譯 -------
CACHE_DIR="${TMPDIR:-/tmp}/draw-free-overlay"
mkdir -p "$CACHE_DIR" 2>/dev/null || CACHE_DIR="/tmp/draw-free-overlay"
BIN="$CACHE_DIR/overlay-text"

run_swift() {
    if command -v swift >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

if ! run_swift; then
    echo "[錯誤] 找不到 swift。請先安裝 Xcode Command Line Tools：" >&2
    echo "       xcode-select --install" >&2
    exit 1
fi

# 需要重建嗎？（執行檔不存在，或原始碼比執行檔新）
REBUILD=0
if [ ! -x "$BIN" ]; then
    REBUILD=1
elif [ "$SWIFT_SRC" -nt "$BIN" ]; then
    REBUILD=1
fi

if [ "$REBUILD" -eq 1 ] && command -v swiftc >/dev/null 2>&1; then
    if ! swiftc -O -o "$BIN" "$SWIFT_SRC" 2>"$CACHE_DIR/compile.log"; then
        echo "[警告] swiftc 編譯失敗，改用直譯模式。編譯訊息：" >&2
        sed 's/^/       /' "$CACHE_DIR/compile.log" >&2
        BIN=""
    fi
else
    [ -x "$BIN" ] || BIN=""
fi

if [ -n "$BIN" ] && [ -x "$BIN" ]; then
    exec "$BIN" "$@"
else
    # 直譯模式（較慢，但保證可跑）
    exec swift "$SWIFT_SRC" "$@"
fi
