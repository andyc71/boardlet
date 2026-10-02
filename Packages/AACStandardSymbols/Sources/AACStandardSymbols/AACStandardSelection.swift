import Foundation

public struct AACStandardSelection: Sendable {
    public let symbol: AACStandardSymbol
    public let imageData: Data

    public init(symbol: AACStandardSymbol, imageData: Data) {
        self.symbol = symbol
        self.imageData = imageData
    }
}
