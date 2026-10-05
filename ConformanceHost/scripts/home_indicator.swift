// home_indicator.swift — which screenshots show the simulator's home indicator.
//
// usage: xcrun swift scripts/home_indicator.swift <list-file>
//   <list-file>: one PNG path per line. Prints `HOME_INDICATOR <path>` for each
//   one that shows the indicator, then `checked <n> with-indicator <k>`.
//
// The conformance screenshots never show the indicator, and a picture that
// does differs from its baseline only there. Measured on iPhone 16 Pro, iOS
// 26.5 (1206 x 2622 px), 2026-10-05: the pill sits in x 387..819, y 2583..2598.
// It came and went with the simulator, not with the fixture: a simulator
// booted since two days drew it on 178 of 178 common/ screenshots and 0 after
// a reboot, and a run 24 minutes after a reboot drew it for six minutes
// (80 screenshots in a row) and on none of them when they were taken again.
//
// The box is held as fractions of the picture so another phone is read at the
// same place; that place was only measured on the device above. A column is
// marked when any pixel of the pill's rows differs from the same column 13 px
// above the pill by more than 60 (sum of RGB); the picture shows the indicator
// when more than a third of the sampled columns are marked. On the device
// above it named the same pictures as an independent reading (PIL) on six
// runs: 0 of 178 and 0 of 901 without the indicator, 178 of 178 twice, 80 of
// 919, and 0 of the 100 taken again.

import CoreGraphics
import Foundation
import ImageIO

func rgba(_ url: URL) -> (width: Int, height: Int, bytes: [UInt8])? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
    let width = image.width, height = image.height
    var bytes = [UInt8](repeating: 0, count: width * height * 4)
    guard let context = CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8,
                                  bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return (width, height, bytes)
}

func showsIndicator(_ url: URL) -> Bool {
    guard let (w, h, px) = rgba(url), h > w else { return false }
    // Fractions of 1206 x 2622: x 400..806 (inside the pill), rows 2586..2595,
    // reference row 2570.
    let x0 = Int(Double(w) * 400 / 1206), x1 = Int(Double(w) * 806 / 1206)
    let y0 = h - 36, y1 = h - 27, ref = h - 52
    func at(_ x: Int, _ y: Int) -> (Int, Int, Int) {
        let i = (y * w + x) * 4
        return (Int(px[i]), Int(px[i + 1]), Int(px[i + 2]))
    }
    var sampled = 0, marked = 0
    for x in stride(from: x0, to: x1, by: 3) {
        sampled += 1
        let r = at(x, ref)
        for y in y0...y1 {
            let p = at(x, y)
            if abs(p.0 - r.0) + abs(p.1 - r.1) + abs(p.2 - r.2) > 60 { marked += 1; break }
        }
    }
    return sampled > 0 && marked * 3 > sampled
}

guard CommandLine.arguments.count == 2,
      let list = try? String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8) else {
    FileHandle.standardError.write("usage: home_indicator.swift <list-file>\n".data(using: .utf8)!)
    exit(2)
}
var checked = 0, found = 0
for line in list.split(separator: "\n") where !line.isEmpty {
    let path = String(line)
    guard FileManager.default.fileExists(atPath: path) else {
        FileHandle.standardError.write("missing: \(path)\n".data(using: .utf8)!)
        exit(2)
    }
    checked += 1
    if showsIndicator(URL(fileURLWithPath: path)) {
        found += 1
        print("HOME_INDICATOR \(path)")
    }
}
print("checked \(checked) with-indicator \(found)")
