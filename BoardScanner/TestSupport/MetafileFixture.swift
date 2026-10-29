import Foundation

/// Original synthetic shapes only. No extracted library symbols.
enum MetafileFixture {
    static func words(_ values: [Int]) -> Data {
        Data(values.flatMap { value in [UInt8(truncatingIfNeeded: value), UInt8(truncatingIfNeeded: value >> 8)] })
    }
    static func longs(_ values: [Int]) -> Data {
        Data(values.flatMap { value in (0..<4).map { UInt8(truncatingIfNeeded: value >> ($0 * 8)) } })
    }
    static func wmRecord(_ op: Int, _ words: [Int] = []) -> Data {
        longs([3 + words.count]) + self.words([op] + words)
    }
    static func wmf(_ records: [Data], bounds: [Int] = [0, 0, 100, 100]) -> Data {
        var placeable = longs([0x9ac6cdd7]) + words([0] + bounds + [1440]) + longs([0])
        let bytes = Array(placeable)
        let checksum = stride(from: 0, to: 20, by: 2).reduce(0) { $0 ^ (Int(bytes[$1]) | Int(bytes[$1 + 1]) << 8) }
        placeable += words([checksum])
        let body = records.reduce(Data(), +) + wmRecord(0)
        let header = words([1, 9, 0x300]) + longs([(18 + body.count) / 2]) + words([16]) + longs([1000]) + words([0])
        return placeable + header + body
    }
    static var redBrush: Data { wmRecord(0x2fc, [0, 255, 0, 0]) }
    static var noPen: Data { wmRecord(0x2fa, [5, 0, 0, 0, 0]) }
    static var rectangle: Data { wmRecord(0x41b, [90, 80, 10, 20]) }
    static var redRectangle: Data {
        wmf([redBrush, wmRecord(0x12d, [0]), noPen, wmRecord(0x12d, [1]), rectangle])
    }
    static func emRecord(_ op: Int, _ payload: Data = Data()) -> Data {
        longs([op, 8 + payload.count]) + payload
    }
    static func emf(_ records: [Data]) -> Data {
        let eof = emRecord(14, longs([0, 16, 20]))
        let body = records.reduce(Data(), +) + eof
        var h = longs([1, 88, 0, 0, 100, 100, 0, 0, 10000, 10000, 0x464d4520, 0x10000,
                       88 + body.count, records.count + 2])
        h += words([16, 0]) + longs([0, 0, 0, 100, 100, 100, 100])
        return h + body
    }
    static var emfRedBrush: [Data] {
        [emRecord(39, longs([1, 0, 255, 0])), emRecord(37, longs([1])), emRecord(37, longs([0x80000008]))]
    }
    static var bezier: Data {
        let points = [10, 10, 90, 10, 90, 90]
        return emf(emfRedBrush + [emRecord(59), emRecord(27, longs([10, 90])),
                    emRecord(88, longs([0, 0, 100, 100, 3]) + words(points)), emRecord(61), emRecord(60),
                    emRecord(63, longs([0, 0, 100, 100]))])
    }
}
