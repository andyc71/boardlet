import Foundation

/// Record-local, little-endian reads. Never casts unaligned source memory.
struct MetafileReader {
    let bytes: [UInt8]
    init(_ data: Data) { bytes = Array(data) }
    init(bytes: [UInt8]) { self.bytes = bytes }
    var count: Int { bytes.count }
    func require(_ offset: Int, _ length: Int) throws {
        guard offset >= 0, length >= 0, offset <= count, length <= count - offset else {
            throw MetafileError.malformed
        }
    }
    func u16(_ offset: Int) throws -> Int {
        try require(offset, 2)
        return Int(bytes[offset]) | Int(bytes[offset + 1]) << 8
    }
    func i16(_ offset: Int) throws -> Int { Int(Int16(bitPattern: UInt16(try u16(offset)))) }
    func u32(_ offset: Int) throws -> Int {
        try require(offset, 4)
        return Int(bytes[offset]) | Int(bytes[offset + 1]) << 8 | Int(bytes[offset + 2]) << 16 | Int(bytes[offset + 3]) << 24
    }
    func i32(_ offset: Int) throws -> Int { Int(Int32(bitPattern: UInt32(try u32(offset)))) }
    func float(_ offset: Int) throws -> Double {
        let value = Double(Float(bitPattern: UInt32(try u32(offset))))
        guard value.isFinite, abs(value) <= 1_000_000 else { throw MetafileError.limit }
        return value
    }
    func record(_ offset: Int, _ length: Int) throws -> MetafileReader {
        try require(offset, length)
        return MetafileReader(bytes: Array(bytes[offset..<offset + length]))
    }
}

enum MetafileError: Error, Equatable, CustomStringConvertible {
    case malformed, limit, empty, unsupported(String)
    var description: String {
        switch self {
        case .malformed: "Malformed metafile"
        case .limit: "Metafile exceeds rendering limits"
        case .empty: "Metafile has no visible artwork"
        case .unsupported(let detail): "Unsupported metafile: \(detail)"
        }
    }
}
