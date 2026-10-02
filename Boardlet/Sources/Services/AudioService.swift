import AVFoundation
import Combine
import Foundation

@MainActor
final class AudioService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    @Published private(set) var playing = false
    @Published private(set) var recording = false
    @Published var notice: String?
    private let speech = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private var recorder: AVAudioRecorder?
    private var continuation: CheckedContinuation<Void, Never>?
    private var work: Task<Void, Never>?
    private var token: NSObjectProtocol?
    private var generation = UUID()
    private var activeUtterance: AVSpeechUtterance?
    private let recordPermission: @MainActor () async -> Bool
    private let session = AudioSessionCoordinator()

    init(recordPermission: @escaping @MainActor () async -> Bool = AudioService.requestRecordPermission) {
        self.recordPermission = recordPermission
        super.init(); speech.delegate = self
        token = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [weak self] notification in
            guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  raw == AVAudioSession.InterruptionType.began.rawValue else { return }
            Task { @MainActor [weak self] in self?.stop(); self?.notice = L("Audio was interrupted. Tap Speak to continue.") }
        }
    }
    func stop() {
        let previous = generation
        generation = UUID(); work?.cancel(); work = nil
        activeUtterance = nil
        speech.stopSpeaking(at: .immediate); player?.stop(); player = nil
        continuation?.resume(); continuation = nil
        playing = false
        if recording { recorder?.stop(); recording = false }
        Task { await session.deactivate(owner: previous) }
    }
    func play(_ cards: [Card], settings: CommunicationSettings, mediaURL: URL) {
        stop(); notice = nil
        let current = generation
        work = Task {
            do {
                guard current == generation, !Task.isCancelled else { return }
                try await session.activate(owner: current, recording: false)
                guard current == generation, !Task.isCancelled else { await session.deactivate(owner: current); return }
                playing = true
                for card in cards {
                    guard current == generation, !Task.isCancelled else { return }
                    if card.voice == .silent { continue }
                    if card.voice == .recording, let recording = card.recording,
                       let audio = try? AVAudioPlayer(contentsOf: mediaURL.appendingPathComponent(recording)) {
                        player = audio; audio.delegate = self
                        await withCheckedContinuation { continuation in
                            self.continuation = continuation
                            if !audio.play() { finishItem(); notice = L("The recording could not be played.") }
                        }
                    } else {
                        if card.voice == .recording { notice = L("Recording unavailable. Speaking the label instead.") }
                        let utterance = AVSpeechUtterance(string: card.label)
                        let selected = card.voiceID ?? settings.voiceID
                        utterance.voice = selected.flatMap(AVSpeechSynthesisVoice.init(identifier:)) ?? AVSpeechSynthesisVoice(language: card.language ?? settings.language)
                        if selected != nil && AVSpeechSynthesisVoice(identifier: selected ?? "") == nil { notice = L("The selected voice is unavailable. Using the system voice.") }
                        if card.label.isEmpty { continue }
                        await withCheckedContinuation { continuation in self.continuation = continuation; activeUtterance = utterance; speech.speak(utterance) }
                    }
                }
                if current == generation { playing = false; await session.deactivate(owner: current) }
            } catch { playing = false; notice = error.localizedDescription }
        }
    }
    private func finishItem() { continuation?.resume(); continuation = nil }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { let id = ObjectIdentifier(utterance); Task { @MainActor in if self.activeUtterance.map(ObjectIdentifier.init) == id { self.activeUtterance = nil; self.finishItem() } } }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { }
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { Task { @MainActor in if self.player === player { self.finishItem() } } }
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) { let id = ObjectIdentifier(player); Task { @MainActor in if self.player.map(ObjectIdentifier.init) == id { self.notice = L("The recording could not be played."); self.finishItem() } } }

    func startRecording() async {
        cancelRecording(); notice = nil
        let request = generation
        let permitted = await recordPermission()
        guard request == generation, !Task.isCancelled else { return }
        guard permitted else { notice = L("Allow Microphone access in Settings to record a voice."); return }
        do {
            try await session.activate(owner: request, recording: true)
            guard request == generation, !Task.isCancelled else { await session.deactivate(owner: request); return }
            let url = URL.temporaryDirectory.appendingPathComponent("boardlet-voice-\(UUID().uuidString).m4a")
            recorder = try AVAudioRecorder(url: url, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue])
            guard recorder?.record() == true else { throw StorageError.invalidData }
            recording = true
        } catch { notice = error.localizedDescription }
    }
    private static func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) } }
    }
    func finishRecording() throws -> Data? {
        guard let recorder else { return nil }
        recorder.stop(); recording = false
        let owner = generation
        defer { try? FileManager.default.removeItem(at: recorder.url); self.recorder = nil; Task { await session.deactivate(owner: owner) } }
        return try Data(contentsOf: recorder.url)
    }
    func cancelRecording() {
        if let recorder { recorder.stop(); try? FileManager.default.removeItem(at: recorder.url) }
        recorder = nil; stop()
    }
    func close() { cancelRecording(); if let token { NotificationCenter.default.removeObserver(token) }; token = nil }
}

/// AVAudioSession activation may block. Keep it off the UI executor, with a
/// matching owner so a delayed stop cannot deactivate a newer playback request.
private actor AudioSessionCoordinator {
    private var owner: UUID?
    func activate(owner: UUID, recording: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        if recording { try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker) }
        else { try session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers) }
        try session.setActive(true)
        self.owner = owner
    }
    func deactivate(owner: UUID) {
        guard self.owner == owner else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        self.owner = nil
    }
}
