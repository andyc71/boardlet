import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// A deliberately bounded GDI subset, based on MS-WMF and MS-EMF. Unknown records
/// fail the entire preview; escape records are never interpreted or executed.
enum MetafileRenderer {
    static func isMetafile(_ data: Data) -> Bool {
        data.starts(with: [0xd7, 0xcd, 0xc6, 0x9a]) ||
        (data.count >= 44 && data.dropFirst(40).prefix(4).elementsEqual([0x20, 0x45, 0x4d, 0x46]))
    }

    static func png(_ data: Data, maximumDimension: Int = 224) throws -> Data {
        try Task.checkCancellation()
        guard data.count <= 4_000_000, (16...512).contains(maximumDimension) else { throw MetafileError.limit }
        let reader = MetafileReader(data)
        let wmf = data.starts(with: [0xd7, 0xcd, 0xc6, 0x9a])
        let bounds: CGRect
        if wmf {
            try reader.require(0, 40)
            var checksum = 0
            for offset in stride(from: 0, to: 20, by: 2) { checksum ^= try reader.u16(offset) }
            guard checksum == (try reader.u16(20)), try reader.u16(14) > 0,
                  try reader.u16(24) == 9, [1, 2].contains(try reader.u16(22)),
                  [0x100, 0x300].contains(try reader.u16(26)) else { throw MetafileError.malformed }
            bounds = try rectangle(reader, 6, short: true)
        } else {
            guard try reader.u32(0) == 1, try reader.u32(40) == 0x464d4520 else { throw MetafileError.malformed }
            bounds = try rectangle(reader, 8)
        }
        guard bounds.width > 0, bounds.height > 0, bounds.width <= 1_000_000,
              bounds.height <= 1_000_000 else { throw MetafileError.limit }
        let canvas = try MetafileCanvas(bounds: wmf ? CGRect(origin: .zero, size: bounds.size) : bounds,
                                        maximumDimension: maximumDimension)
        if wmf {
            canvas.state.windowOrigin = bounds.origin
            canvas.state.windowExtent = bounds.size
            canvas.state.viewportExtent = bounds.size
            try canvas.wmf(reader)
        } else { try canvas.emf(reader) }
        return try canvas.png()
    }

    static func rectangle(_ r: MetafileReader, _ offset: Int, short: Bool = false) throws -> CGRect {
        let step = short ? 2 : 4
        let a = try (0..<4).map { short ? try r.i16(offset + $0 * step) : try r.i32(offset + $0 * step) }
        guard a[2] > a[0], a[3] > a[1] else { throw MetafileError.malformed }
        return CGRect(x: a[0], y: a[1], width: a[2] - a[0], height: a[3] - a[1])
    }
}

struct MetafilePen {
    var color = 0
    var width: CGFloat = 1
    var style = 0
    var cosmetic = false
}
enum MetafileObject {
    case pen(MetafilePen), brush(Int?)
}
struct MetafileState {
    var pen = MetafilePen()
    var brush: Int? = 0xffffff
    var windowOrigin = CGPoint.zero
    var windowExtent = CGSize(width: 1, height: 1)
    var viewportOrigin = CGPoint.zero
    var viewportExtent = CGSize(width: 1, height: 1)
    var world = CGAffineTransform.identity
    var current = CGPoint.zero // GDI current position is in logical coordinates.
    var winding = false
    var miter: CGFloat = 10
    var clips: [(CGPath, Bool)] = []
}

/// Confined to one synchronous rendering call on the import worker, never shared.
final class MetafileCanvas {
    let context: CGContext
    let width: Int
    let height: Int
    var state = MetafileState()
    var saved: [MetafileState] = []
    var objects: [Int: MetafileObject] = [:]
    var objectLimit = 0
    var pointCount = 0
    var drawingCount = 0
    var path = CGMutablePath()
    var buildingPath = false
    var readyPath = false

    init(bounds: CGRect, maximumDimension: Int) throws {
        let scale = CGFloat(maximumDimension) / max(bounds.width, bounds.height)
        width = max(2, Int(ceil(bounds.width * scale)))
        height = max(2, Int(ceil(bounds.height * scale)))
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw MetafileError.limit }
        self.context = context
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: CGFloat(width) / bounds.width, y: -CGFloat(height) / bounds.height)
        context.translateBy(x: -bounds.minX, y: -bounds.minY)
        context.setAllowsAntialiasing(true)
    }

    func png() throws -> Data {
        try Task.checkCancellation()
        guard !buildingPath, !readyPath, drawingCount > 0,
              let pixels = context.data?.assumingMemoryBound(to: UInt8.self),
              (0..<width * height).contains(where: { pixels[$0 * 4 + 3] != 0 }),
              let image = context.makeImage() else { throw MetafileError.empty }
        let data = NSMutableData()
        guard let target = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw MetafileError.limit
        }
        CGImageDestinationAddImage(target, image, nil)
        guard CGImageDestinationFinalize(target) else { throw MetafileError.limit }
        return data as Data
    }

    func transform() throws -> CGAffineTransform {
        guard state.windowExtent.width != 0, state.windowExtent.height != 0,
              state.viewportExtent.width != 0, state.viewportExtent.height != 0 else { throw MetafileError.malformed }
        let sx = state.viewportExtent.width / state.windowExtent.width
        let sy = state.viewportExtent.height / state.windowExtent.height
        let mapping = CGAffineTransform(a: sx, b: 0, c: 0, d: sy,
                                       tx: state.viewportOrigin.x - state.windowOrigin.x * sx,
                                       ty: state.viewportOrigin.y - state.windowOrigin.y * sy)
        let t = state.world.concatenating(mapping)
        guard [t.a, t.b, t.c, t.d, t.tx, t.ty].allSatisfy({ $0.isFinite && abs($0) <= 1_000_000 }),
              abs(t.a * t.d - t.b * t.c) > 1e-12 else { throw MetafileError.limit }
        return t
    }

    func point(_ x: Int, _ y: Int) throws -> CGPoint {
        try mappedPoint(CGPoint(x: x, y: y))
    }

    func mappedPoint(_ logical: CGPoint) throws -> CGPoint {
        pointCount += 1
        guard pointCount <= 200_000 else { throw MetafileError.limit }
        if pointCount % 256 == 0 { try Task.checkCancellation() }
        let p = logical.applying(try transform())
        guard p.x.isFinite, p.y.isFinite, abs(p.x) <= 10_000_000, abs(p.y) <= 10_000_000 else { throw MetafileError.limit }
        return p
    }

    func color(_ value: Int) -> CGColor {
        CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                components: [CGFloat(value & 255) / 255, CGFloat((value >> 8) & 255) / 255,
                             CGFloat((value >> 16) & 255) / 255, 1])!
    }

    func paint(_ p: CGPath, fill: Bool, stroke: Bool) throws {
        guard !p.isEmpty else { throw MetafileError.malformed }
        context.saveGState()
        defer { context.restoreGState() }
        for (clip, winding) in state.clips {
            context.addPath(clip)
            context.clip(using: winding ? .winding : .evenOdd)
        }
        if fill, let brush = state.brush {
            context.setFillColor(color(brush))
            context.addPath(p)
            context.fillPath(using: state.winding ? .winding : .evenOdd)
            drawingCount += 1
        }
        if stroke, state.pen.style & 15 != 5 {
            let pen = state.pen
            let t = try transform()
            // Paths store device points, preserving transforms at path-construction time.
            // Return to current logical space for geometrically transformed stroke widths.
            var inverse = t.inverted()
            guard let logical = p.copy(using: &inverse) else { throw MetafileError.malformed }
            context.concatenate(t)
            context.setStrokeColor(color(pen.color))
            let scale = max(hypot(t.a, t.b), hypot(t.c, t.d))
            context.setLineWidth(pen.width == 0 || pen.cosmetic ? max(1, pen.width) / scale : pen.width)
            context.setLineCap(pen.style & 0xf00 == 0x200 ? .butt : (pen.style & 0xf00 == 0x100 ? .square : .round))
            context.setLineJoin(pen.style & 0xf000 == 0x2000 ? .miter : (pen.style & 0xf000 == 0x1000 ? .bevel : .round))
            context.setMiterLimit(state.miter)
            context.addPath(logical)
            context.strokePath()
            drawingCount += 1
        }
    }

    func closedFigures(_ source: CGPath) -> CGPath {
        let result = CGMutablePath()
        var open = false
        source.applyWithBlock { element in
            let e = element.pointee
            switch e.type {
            case .moveToPoint:
                if open { result.closeSubpath() }
                result.move(to: e.points[0]); open = true
            case .addLineToPoint: result.addLine(to: e.points[0]); open = true
            case .addQuadCurveToPoint: result.addQuadCurve(to: e.points[1], control: e.points[0]); open = true
            case .addCurveToPoint: result.addCurve(to: e.points[2], control1: e.points[0], control2: e.points[1]); open = true
            case .closeSubpath: result.closeSubpath(); open = false
            @unknown default: break
            }
        }
        if open { result.closeSubpath() }
        return result
    }

    func addObject(_ object: MetafileObject, handle: Int? = nil) throws {
        let id: Int
        if let handle {
            guard handle > 0 else { throw MetafileError.malformed } // EMF index zero is reserved.
            id = handle
        } else {
            guard let free = (0..<objectLimit).first(where: { objects[$0] == nil }) else { throw MetafileError.malformed }
            id = free
        }
        guard id >= 0, id < objectLimit, objects[id] == nil else { throw MetafileError.malformed }
        objects[id] = object
    }

    func select(_ id: Int, emf: Bool = false) throws {
        let object: MetafileObject
        if emf && id & 0x80000000 != 0 {
            switch id & 0x7fffffff {
            case 0: object = .brush(0xffffff)
            case 1: object = .brush(0xc0c0c0)
            case 2: object = .brush(0x808080)
            case 3: object = .brush(0x404040)
            case 4: object = .brush(0)
            case 5: object = .brush(nil)
            case 6: object = .pen(MetafilePen(color: 0xffffff))
            case 7: object = .pen(MetafilePen())
            case 8: object = .pen(MetafilePen(style: 5))
            default: throw MetafileError.unsupported("stock object \(id)")
            }
        } else {
            guard let found = objects[id] else { throw MetafileError.malformed }
            object = found
        }
        switch object {
        case .pen(let pen): state.pen = pen
        case .brush(let color): state.brush = color
        }
    }

    func delete(_ id: Int) throws {
        guard objects.removeValue(forKey: id) != nil else { throw MetafileError.malformed }
        // GDI selection retains the value; deleting a handle does not select defaults.
    }

    func save() throws {
        guard saved.count < 64 else { throw MetafileError.limit }
        saved.append(state)
    }
    func restore(_ level: Int) throws {
        let index = level < 0 ? saved.count + level : level - 1
        guard saved.indices.contains(index) else { throw MetafileError.malformed }
        state = saved[index]
        saved.removeSubrange(index...)
    }
    func fillMode(_ mode: Int) throws {
        guard mode == 1 || mode == 2 else { throw MetafileError.malformed }
        state.winding = mode == 2
    }
    func pen(style: Int, width: Int, color: Int, cosmetic: Bool = false) throws -> MetafilePen {
        guard color & 0xff000000 == 0, [0, 5].contains(style & 15), style & ~0x1330f == 0,
              [0, 0x100, 0x200].contains(style & 0xf00),
              [0, 0x1000, 0x2000].contains(style & 0xf000), abs(width) <= 100_000 else {
            throw MetafileError.unsupported("pen style/width")
        }
        return MetafilePen(color: color, width: CGFloat(abs(width)), style: style, cosmetic: cosmetic)
    }
    func brush(style: Int, color: Int) throws -> MetafileObject {
        guard color & 0xff000000 == 0, style == 0 || style == 1 else { throw MetafileError.unsupported("brush style \(style)") }
        return .brush(style == 1 ? nil : color)
    }
    func clip(_ p: CGPath) throws {
        guard state.clips.count < 64 else { throw MetafileError.limit }
        state.clips.append((p, state.winding))
    }
}
