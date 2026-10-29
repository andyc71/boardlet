import CoreGraphics
import Foundation

extension MetafileCanvas {
    func emf(_ file: MetafileReader) throws {
        let end = try file.u32(48), expectedRecords = try file.u32(52)
        objectLimit = try file.u16(56)
        guard end == file.count, (1...4096).contains(objectLimit), (2...50_000).contains(expectedRecords) else {
            throw MetafileError.limit
        }
        var offset = 0, records = 0
        while offset < end {
            try Task.checkCancellation()
            records += 1
            guard records <= expectedRecords else { throw MetafileError.malformed }
            let size = try file.u32(offset + 4)
            guard size >= 8, size % 4 == 0, size <= end - offset else { throw MetafileError.malformed }
            let r = try file.record(offset, size), op = try r.u32(0)
            offset += size
            switch op {
            case 1:
                guard records == 1, size >= 88, try r.u32(44) == 0x10000 else { throw MetafileError.malformed }
            case 14:
                try r.require(0, 20)
                guard offset == end, records == expectedRecords, try r.u32(8) == 0 else { throw MetafileError.malformed }
                return
            case 17:
                guard try r.u32(8) == 8 else { throw MetafileError.unsupported("mapping mode") }
            case 18:
                guard [1, 2].contains(try r.u32(8)) else { throw MetafileError.malformed }
            case 19: try fillMode(r.u32(8))
            case 20:
                guard try r.u32(8) == 13 else { throw MetafileError.unsupported("raster mix mode") }
            case 9: state.windowExtent = try emfSize(r)
            case 10: state.windowOrigin = try emfPoint(r)
            case 11: state.viewportExtent = try emfSize(r)
            case 12: state.viewportOrigin = try emfPoint(r)
            case 33: try save()
            case 34: try restore(r.i32(8))
            case 35: state.world = try worldTransform(r)
            case 36:
                let t = try worldTransform(r)
                switch try r.u32(32) {
                case 1: state.world = .identity
                case 2: state.world = t.concatenating(state.world)
                case 3: state.world = state.world.concatenating(t)
                case 4: state.world = t
                default: throw MetafileError.malformed
                }
            case 37: try select(r.u32(8), emf: true)
            case 38:
                try addObject(.pen(pen(style: r.u32(12), width: r.i32(16), color: r.u32(24))), handle: r.u32(8))
            case 39:
                try r.require(0, 24)
                try addObject(brush(style: r.u32(12), color: r.u32(16)), handle: r.u32(8))
            case 40: try delete(r.u32(8))
            case 95:
                guard try r.u32(16) == 0, try r.u32(24) == 0, try r.u32(36) == 0, try r.u32(48) == 0 else {
                    throw MetafileError.unsupported("extended pen brush or dash")
                }
                let style = try r.u32(28)
                try addObject(.pen(pen(style: style, width: r.u32(32), color: r.u32(40),
                                       cosmetic: style & 0x10000 == 0)), handle: r.u32(8))
            case 58:
                let limit = try r.u32(8)
                guard limit >= 1, limit <= 1000 else { throw MetafileError.limit }
                state.miter = CGFloat(limit)
            case 27:
                state.current = try emfPoint(r)
                if buildingPath { path.move(to: try mappedPoint(state.current)) }
            case 54:
                let next = try point(r.i32(8), r.i32(12))
                if buildingPath { if path.isEmpty { path.move(to: try mappedPoint(state.current)) }; path.addLine(to: next) }
                else {
                    let p = CGMutablePath(); p.move(to: try mappedPoint(state.current)); p.addLine(to: next)
                    try paint(p, fill: false, stroke: true)
                }
                state.current = try emfPoint(r)
            case 59:
                guard !buildingPath else { throw MetafileError.malformed }
                path = CGMutablePath(); buildingPath = true; readyPath = false
            case 60:
                guard buildingPath else { throw MetafileError.malformed }
                buildingPath = false; readyPath = true
            case 61:
                guard buildingPath, !path.isEmpty else { throw MetafileError.malformed }
                path.closeSubpath(); state.current = path.currentPoint.applying(try transform().inverted())
            case 62, 63, 64:
                try r.require(8, 16) // Bounds are hints only (some Adobe files contain sentinel bounds).
                guard readyPath, !buildingPath else { throw MetafileError.malformed }
                try paint(op == 63 ? closedFigures(path) : path, fill: op != 64, stroke: op != 62)
                path = CGMutablePath(); readyPath = false
            case 67:
                guard readyPath, try r.u32(8) == 1 else { throw MetafileError.unsupported("clip path mode") }
                try clip(path); path = CGMutablePath(); readyPath = false
            case 68: path = CGMutablePath(); readyPath = false; buildingPath = false
            case 30, 42, 43:
                let rect = try MetafileRenderer.rectangle(r, 8)
                let p = CGMutablePath(), t = try transform()
                if op == 42 { p.addEllipse(in: rect, transform: t) } else { p.addRect(rect, transform: t) }
                if op == 30 { try clip(p) }
                else if buildingPath { path.addPath(p) }
                else { try paint(p, fill: true, stroke: true) }
            case 2...8, 85...91: try emfPoly(r, op: op)
            default: throw MetafileError.unsupported("EMF record \(op)")
            }
            _ = try transform()
        }
        throw MetafileError.malformed
    }

    private func emfPoint(_ r: MetafileReader) throws -> CGPoint { try CGPoint(x: r.i32(8), y: r.i32(12)) }
    private func emfSize(_ r: MetafileReader) throws -> CGSize { try CGSize(width: r.i32(8), height: r.i32(12)) }
    private func worldTransform(_ r: MetafileReader) throws -> CGAffineTransform {
        try CGAffineTransform(a: r.float(8), b: r.float(12), c: r.float(16), d: r.float(20), tx: r.float(24), ty: r.float(28))
    }

    private func emfPoly(_ r: MetafileReader, op: Int) throws {
        let short = op >= 85, kind = short ? op - 83 : op, stride = short ? 4 : 8
        let p = buildingPath ? path : CGMutablePath()
        let count = try r.u32(24)
        guard count > 0, count <= 200_000 else { throw MetafileError.limit }
        if kind == 7 || kind == 8 {
            guard count <= 4096 else { throw MetafileError.limit }
            let total = try r.u32(28)
            guard total <= 200_000 else { throw MetafileError.limit }
            try r.require(32, count * 4 + total * stride)
            var start = 32 + count * 4, sum = 0
            for i in 0..<count {
                let n = try r.u32(32 + i * 4)
                guard n <= total - sum else { throw MetafileError.malformed }
                try appendPoints(r, offset: start, count: n, short: short, to: p, close: kind == 8)
                start += n * stride; sum += n
            }
            guard sum == total else { throw MetafileError.malformed }
        } else {
            try r.require(28, count * stride)
            func read(_ index: Int) throws -> CGPoint {
                let at = 28 + index * stride
                return try short ? point(r.i16(at), r.i16(at + 2)) : point(r.i32(at), r.i32(at + 4))
            }
            if kind == 2 || kind == 5 {
                let start = kind == 2 ? 1 : 0
                guard count >= start + 3, (count - start) % 3 == 0 else { throw MetafileError.malformed }
                if start == 1 { p.move(to: try read(0)) }
                else if p.isEmpty { p.move(to: try mappedPoint(state.current)) }
                for i in Swift.stride(from: start, to: count, by: 3) {
                    let a = try read(i), b = try read(i + 1), c = try read(i + 2)
                    p.addCurve(to: c, control1: a, control2: b)
                }
            } else if kind == 6 {
                if p.isEmpty { p.move(to: try mappedPoint(state.current)) }
                for i in 0..<count { p.addLine(to: try read(i)) }
            } else {
                try appendPoints(r, offset: 28, count: count, short: short, to: p, close: kind == 3)
            }
            if kind == 5 || kind == 6 { state.current = p.currentPoint.applying(try transform().inverted()) }
        }
        if !buildingPath { try paint(p, fill: kind == 3 || kind == 8, stroke: true) }
    }
}
