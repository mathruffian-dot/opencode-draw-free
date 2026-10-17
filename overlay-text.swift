//
// overlay-text.swift — 在圖片上加上對話框與中文字（macOS 原生版）
//
// 這是 overlay-text.ps1（Windows / System.Drawing 版）的 macOS 移植版，
// 行為與預設值完全一致，使用 AppKit（不需安裝任何套件、不需 Pillow、不需 ImageMagick）。
//
// 用法（建議透過 overlay-text.sh 呼叫，或用 `swift overlay-text.swift ...`）：
//   overlay-text.swift --src in.png --dst out.png \
//       --text "壓力？那能吃嗎？" --subtitle "— 卡皮巴拉的人生哲學"
//
// 也接受 PowerShell 風格的參數名稱：-SrcPath / -DstPath / -Text / -Subtitle
//
import AppKit
import Foundation

// ---------------- 參數解析 ----------------
var srcPath = ""
var dstPath = ""
var text = "壓力？那能吃嗎？"
var subtitle = "— 卡皮巴拉的人生哲學"
var fontName = ""          // 空字串 = 自動挑選支援中文的字型
var mainSize: CGFloat = 42
var subSize: CGFloat = 22
var bubbleW: CGFloat = 560
var bubbleH: CGFloat = 160
var bubbleTop: CGFloat = 60
var radius: CGFloat = 30

var positional: [String] = []

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write(("[錯誤] " + msg + "\n").data(using: .utf8)!)
    exit(1)
}

let argv = Array(CommandLine.arguments.dropFirst())
var idx = 0
while idx < argv.count {
    let a = argv[idx]
    func value() -> String {
        idx += 1
        return idx < argv.count ? argv[idx] : ""
    }

    switch a {
    case "--src", "-SrcPath":
        srcPath = value()
    case "--dst", "-DstPath":
        dstPath = value()
    case "--text", "-Text":
        text = value()
    case "--subtitle", "-Subtitle":
        subtitle = value()
    case "--font":
        fontName = value()
    case "--main-size":
        mainSize = CGFloat(Double(value()) ?? 42)
    case "--sub-size":
        subSize = CGFloat(Double(value()) ?? 22)
    case "--bubble-w":
        bubbleW = CGFloat(Double(value()) ?? 560)
    case "--bubble-h":
        bubbleH = CGFloat(Double(value()) ?? 160)
    case "-h", "--help":
        print("""
        用法：overlay-text --src IN --dst OUT [--text T] [--subtitle S] [--font NAME]
                           [--main-size N] [--sub-size N] [--bubble-w N] [--bubble-h N]

          --src       來源圖片路徑（必填）
          --dst       輸出圖片路徑（必填，PNG）
          --text      對話框主文字（預設：壓力？那能吃嗎？）
          --subtitle  底部副標（預設：— 卡皮巴拉的人生哲學；給空字串則不畫）
          --font      指定字型名稱（預設自動：PingFang TC / Heiti TC / 系統字型）
        """)
        exit(0)
    default:
        if a.hasPrefix("-") {
            fail("未知參數 \(a)")
        }
        positional.append(a)
    }
    idx += 1
}

if srcPath.isEmpty, positional.count >= 1 { srcPath = positional[0] }
if dstPath.isEmpty, positional.count >= 2 { dstPath = positional[1] }

if srcPath.isEmpty || dstPath.isEmpty {
    fail("必須提供 --src 與 --dst（或前兩個位置參數）")
}

// ---------------- 載入原圖 ----------------
guard let image = NSImage(contentsOfFile: srcPath) else {
    fail("無法讀取來源圖片：\(srcPath)")
}
var proposed = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
guard let cg = image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
    fail("無法解碼來源圖片（可能不是有效圖檔）：\(srcPath)")
}
let W = cg.width
let H = cg.height

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: W, pixelsHigh: H,
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
) else {
    fail("無法建立輸出畫布")
}

// ---------------- 開始繪圖 ----------------
NSGraphicsContext.saveGraphicsState()
guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
    fail("無法建立繪圖環境")
}
NSGraphicsContext.current = ctx
let cgctx = ctx.cgContext
cgctx.setShouldAntialias(true)

// 先畫原圖（AppKit 預設左下為原點；CGImage 會正向繪出）
cgctx.draw(cg, in: CGRect(x: 0, y: 0, width: W, height: H))

// 左上為原點的 y 轉換：topY 是距離頂端的距離，height 是元素高度
func bottomY(_ topY: CGFloat, _ height: CGFloat) -> CGFloat {
    return CGFloat(H) - topY - height
}

// === 對話框（圓角矩形，白底黑框）===
// 小圖時自動縮窄，避免超出畫布
var bw = min(bubbleW, CGFloat(W) - 40)
if bw < 200 { bw = CGFloat(W) * 0.9 }
let bx = (CGFloat(W) - bw) / 2
let bh = bubbleH

let bubbleRect = NSRect(x: bx, y: bottomY(bubbleTop, bh), width: bw, height: bh)
let bubblePath = NSBezierPath(roundedRect: bubbleRect, xRadius: radius, yRadius: radius)
NSColor.white.setFill()
bubblePath.fill()
NSColor.black.setStroke()
bubblePath.lineWidth = 5
bubblePath.stroke()

// === 對話框尾巴（三角形指向下方主角）===
let bubbleBottomY = bubbleTop + bh
let tailStart = bx + 180
let p1 = NSPoint(x: tailStart, y: bottomY(bubbleBottomY, 0))
let p2 = NSPoint(x: tailStart - 50, y: bottomY(bubbleBottomY + 70, 0))
let p3 = NSPoint(x: tailStart + 80, y: bottomY(bubbleBottomY, 0))

let tail = NSBezierPath()
tail.move(to: p1)
tail.line(to: p2)
tail.line(to: p3)
tail.close()
NSColor.white.setFill()
tail.fill()

NSColor.black.setStroke()
for (a, b) in [(p1, p2), (p2, p3)] {
    let seg = NSBezierPath()
    seg.move(to: a)
    seg.line(to: b)
    seg.lineWidth = 5
    seg.stroke()
}

// === 字型（優先支援繁體中文）===
func cjkFont(bold: Bool, size: CGFloat) -> NSFont {
    if !fontName.isEmpty, let f = NSFont(name: fontName, size: size) {
        return f
    }
    let candidates = bold
        ? ["PingFangTC-Semibold", "PingFang TC", "Heiti TC", "STHeitiSC-Medium"]
        : ["PingFangTC-Regular", "PingFang TC", "Heiti TC", "STHeitiSC-Light"]
    for name in candidates {
        if let f = NSFont(name: name, size: size) { return f }
    }
    return bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
}

let centerPara = NSMutableParagraphStyle()
centerPara.alignment = .center
centerPara.lineBreakMode = .byWordWrapping

// === 主文字 ===
let mainAttrs: [NSAttributedString.Key: Any] = [
    .font: cjkFont(bold: true, size: mainSize),
    .foregroundColor: NSColor(srgbRed: 60 / 255.0, green: 60 / 255.0, blue: 60 / 255.0, alpha: 1),
    .paragraphStyle: centerPara,
]
let mainStr = NSAttributedString(string: text, attributes: mainAttrs)
let innerW = bw - 20
let innerH = bh - 20
let mainBox = mainStr.boundingRect(
    with: NSSize(width: innerW, height: innerH),
    options: [.usesLineFragmentOrigin, .usesFontLeading]
)
let mainTop = bubbleTop + 10 + (innerH - mainBox.height) / 2
let mainRect = NSRect(x: bx + 10, y: bottomY(mainTop, mainBox.height),
                      width: innerW, height: mainBox.height)
mainStr.draw(in: mainRect)

// === 底部副標 ===
if !subtitle.isEmpty {
    let subAttrs: [NSAttributedString.Key: Any] = [
        .font: cjkFont(bold: false, size: subSize),
        .foregroundColor: NSColor.white,
        .paragraphStyle: centerPara,
    ]
    let subStr = NSAttributedString(string: subtitle, attributes: subAttrs)
    let sb = subStr.boundingRect(
        with: NSSize(width: CGFloat(W), height: 1000),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
    let sw = ceil(sb.width) + 30
    let sh = ceil(sb.height) + 10
    let sx = (CGFloat(W) - sw) / 2
    let subTop = CGFloat(H) - sh - 30

    let subRect = NSRect(x: sx, y: bottomY(subTop, sh), width: sw, height: sh)
    let subPath = NSBezierPath(roundedRect: subRect, xRadius: 12, yRadius: 12)
    NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 120 / 255.0).setFill()
    subPath.fill()

    let subTextRect = NSRect(
        x: sx,
        y: bottomY(subTop, sh) + (sh - sb.height) / 2,
        width: sw,
        height: sb.height
    )
    subStr.draw(in: subTextRect)
}

NSGraphicsContext.restoreGraphicsState()

// ---------------- 儲存 ----------------
guard let png = rep.representation(using: .png, properties: [:]) else {
    fail("無法編碼輸出 PNG")
}
do {
    try png.write(to: URL(fileURLWithPath: dstPath))
} catch {
    fail("無法寫入檔案 \(dstPath)：\(error.localizedDescription)")
}

print("[OK] 已加上對話框：\(dstPath)")
