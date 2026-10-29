import Foundation

struct AccessSettings: Codable, Equatable {
    enum Mode: String, Codable, CaseIterable, Identifiable {
        case direct, manual, automatic
        var id: Self { self }
        var title: String {
            switch self {
            case .direct: "Touch"
            case .manual: "Step scanning"
            case .automatic: "Automatic scanning"
            }
        }
    }

    var mode: Mode = .direct
    var scanInterval: Double = 1.5
    var repeatDelay: Double = 0
    var buttonScale: Double = 1

    var validated: Self {
        var copy = self
        copy.scanInterval = scanInterval.isFinite ? min(5, max(0.5, scanInterval)) : 1.5
        copy.repeatDelay = repeatDelay.isFinite ? min(2, max(0, repeatDelay)) : 0
        copy.buttonScale = buttonScale.isFinite ? min(2, max(1, buttonScale)) : 1
        return copy
    }
}
