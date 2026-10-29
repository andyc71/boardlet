import Foundation

@MainActor
protocol SpeechOutput: AnyObject {
    @discardableResult
    func speak(_ text: String, settings: CommunicationSettings) -> Bool
    func stop()
}
