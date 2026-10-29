import CoreGraphics
import Foundation

extension MetafileCanvas {
    func wmf(_ file: MetafileReader) throws {
        objectLimit = try file.u16(32)
        guard (1...4096).contains(objectLimit) else { throw MetafileError.limit }
        let end = try 22 + file.u32(28) * 2
        // Some writers include a zero alignment WORD after EOF in the declared size.
        guard end <= file.count, end >= 46, file.count - end <= 2 else { throw MetafileError.malformed }
        var offset = 40, records = 0
        while offset < end {
            try Task.checkCancellation()
            records += 1
            guard records <= 50_000 else { throw MetafileError.limit }
            let size = try file.u32(offset) * 2
            guard size >= 6, size <= end - offset else { throw MetafileError.malformed }
            let r = try file.record(offset, size), op = try r.u16(4)
            offset += size
            switch op {
            case 0:
                guard size == 6, end - offset <= 2,
                      file.bytes[offset..<file.count].allSatisfy({ $0 == 0 }) else { throw MetafileError.malformed }
                return
            case 0x103: // MM_ANISOTROPIC; other modes need physical-device metrics.
                guard try r.u16(6) == 8 else { throw MetafileError.unsupported("mapping mode") }
            case 0x20b: state.windowOrigin = try wmfPair(r)
            case 0x20c:
                let p = try wmfPair(r); state.windowExtent = CGSize(width: p.x, height: p.y)
            case 0x20d: state.viewportOrigin = try wmfPair(r)
            case 0x20e:
                let p = try wmfPair(r); state.viewportExtent = CGSize(width: p.x, height: p.y)
            case 0x20f:
                let p = try wmfPair(r); state.windowOrigin.x += p.x; state.windowOrigin.y += p.y
            case 0x211:
                let p = try wmfPair(r); state.viewportOrigin.x += p.x; state.viewportOrigin.y += p.y
            case 0x106: try fillMode(r.u16(6))
            case 0x102: // No text or dashed pens are supported, so background mode has no drawing effect.
                guard [1, 2].contains(try r.u16(6)) else { throw MetafileError.malformed }
            case 0x104:
                guard try r.u16(6) == 13 else { throw MetafileError.unsupported("raster mix mode") }
            case 0x2fa:
                try addObject(.pen(pen(style: r.u16(6), width: r.i16(8), color: r.u32(12))))
            case 0x2fc:
                try r.require(0, 14)
                try addObject(brush(style: r.u16(6), color: r.u32(8)))
            case 0x12d: try select(r.u16(6))
            case 0x1f0: try delete(r.u16(6))
            case 0x1e: try save()
            case 0x127: try restore(r.i16(6))
            case 0x214: state.current = try wmfPair(r)
            case 0x213:
                let p = CGMutablePath(); p.move(to: try mappedPoint(state.current))
                state.current = try wmfPair(r); p.addLine(to: try mappedPoint(state.current))
                try paint(p, fill: false, stroke: true)
            case 0x324, 0x325:
                let n = try r.u16(6)
                guard n >= 2 else { throw MetafileError.malformed }
                try r.require(8, n * 4)
                let p = CGMutablePath()
                try appendPoints(r, offset: 8, count: n, short: true, to: p, close: op == 0x324)
                try paint(p, fill: op == 0x324, stroke: true)
            case 0x538:
                let n = try r.u16(6)
                guard n > 0, n <= 4096 else { throw MetafileError.limit }
                try r.require(8, n * 2)
                var start = 8 + n * 2
                let p = CGMutablePath()
                for i in 0..<n {
                    let count = try r.u16(8 + i * 2)
                    guard count >= 2 else { throw MetafileError.malformed }
                    try appendPoints(r, offset: start, count: count, short: true, to: p, close: true)
                    start += count * 4
                }
                try paint(p, fill: true, stroke: true)
            case 0x41b, 0x418, 0x416:
                let x = try r.i16(12), y = try r.i16(10)
                let right = try r.i16(8), bottom = try r.i16(6)
                guard right > x, bottom > y else { throw MetafileError.malformed }
                let rect = CGRect(x: x, y: y, width: right - x, height: bottom - y)
                let p = CGMutablePath(); let t = try transform()
                if op == 0x418 { p.addEllipse(in: rect, transform: t) } else { p.addRect(rect, transform: t) }
                if op == 0x416 { try clip(p) } else { try paint(p, fill: true, stroke: true) }
            case 0xf43: try stretchDIB(r)
            default: throw MetafileError.unsupported("WMF record 0x\(String(op, radix: 16))")
            }
            _ = try transform()
        }
        throw MetafileError.malformed // EOF is required.
    }

    private func wmfPair(_ r: MetafileReader) throws -> CGPoint { try CGPoint(x: r.i16(8), y: r.i16(6)) }

    func appendPoints(_ r: MetafileReader, offset: Int, count: Int, short: Bool,
                      to p: CGMutablePath, close: Bool) throws {
        let stride = short ? 4 : 8
        guard count >= 2, count <= 200_000 else { throw MetafileError.limit }
        try r.require(offset, count * stride)
        for i in 0..<count {
            let at = offset + i * stride
            let next = try short ? point(r.i16(at), r.i16(at + 2)) : point(r.i32(at), r.i32(at + 4))
            if i == 0 { p.move(to: next) } else { p.addLine(to: next) }
        }
        if close { p.closeSubpath() }
    }

    /// BI_RGB 24-bit DIB, SRCCOPY, full source rectangle. Other bitmap encodings
    /// are rejected explicitly rather than treating palette/compression data as pixels.
    private func stretchDIB(_ r: MetafileReader) throws {
        guard try r.u32(6) == 0x00cc0020, try r.u16(10) == 0,
              try r.u32(28) == 40, try r.u16(40) == 1,
              try r.u16(42) == 24, try r.u32(44) == 0, try r.u32(60) == 0 else {
            throw MetafileError.unsupported("DIB encoding or raster operation")
        }
        let w = try r.i32(32), signedHeight = try r.i32(36), h = abs(signedHeight)
        guard w > 0, h > 0, w <= 2048, h <= 2048 else { throw MetafileError.limit }
        guard try r.i16(12) == h, try r.i16(14) == w, try r.i16(16) == 0, try r.i16(18) == 0 else {
            throw MetafileError.unsupported("DIB source crop")
        }
        let rowBytes = (w * 3 + 3) & ~3
        try r.require(68, rowBytes * h)
        var rgba = [UInt8](repeating: 255, count: w * h * 4)
        for y in 0..<h {
            try Task.checkCancellation()
            let sourceRow = signedHeight > 0 ? h - 1 - y : y
            for x in 0..<w {
                let source = 68 + sourceRow * rowBytes + x * 3, dest = (y * w + x) * 4
                rgba[dest] = r.bytes[source + 2]; rgba[dest + 1] = r.bytes[source + 1]; rgba[dest + 2] = r.bytes[source]
            }
        }
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            throw MetafileError.malformed
        }
        let dh = try r.i16(20), dw = try r.i16(22), y = try r.i16(24), x = try r.i16(26)
        guard dh > 0, dw > 0 else { throw MetafileError.unsupported("mirrored DIB") }
        context.saveGState(); defer { context.restoreGState() }
        for (clip, winding) in state.clips { context.addPath(clip); context.clip(using: winding ? .winding : .evenOdd) }
        context.concatenate(try transform())
        context.translateBy(x: CGFloat(x), y: CGFloat(y + dh))
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(x: 0, y: 0, width: dw, height: dh))
        drawingCount += 1
    }
}
