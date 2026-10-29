import Foundation

struct CommunicationSettings: Codable, Equatable {
    var voiceIdentifier = ""
    var voiceLocale: String? = nil
    var rate: Float = 0.5
    var speakOnSelection = true
    var clearAfterSpeaking = false

    var validated: Self {
        var result = self
        result.rate = rate.isFinite ? min(0.65, max(0.25, rate)) : 0.5
        return result
    }
}
