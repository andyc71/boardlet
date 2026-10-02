import AVFoundation
import UIKit
import XCTest
@testable import MediaFramework

final class AudioHelperTests: XCTestCase {
    private enum Failure: Error { case session }

    private final class Session: SpeechAudioSession {
        var categories: [(AVAudioSession.Category, AVAudioSession.Mode, AVAudioSession.CategoryOptions)] = []
        var transitions: [(Bool, AVAudioSession.SetActiveOptions)] = []
        var failCategory = false
        var failActivation = false
        var failDeactivation = false

        func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
            categories.append((category, mode, options))
            if failCategory { throw Failure.session }
        }

        func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
            transitions.append((active, options))
            if active ? failActivation : failDeactivation { throw Failure.session }
        }
    }

    private final class Synthesizer: AVSpeechSynthesizer {
        var utterances: [AVSpeechUtterance] = []
        var stopCount = 0
        var canStop = true
        var onSpeak: (() -> Void)?

        override var isSpeaking: Bool { !utterances.isEmpty }

        override func speak(_ utterance: AVSpeechUtterance) {
            onSpeak?()
            utterances.append(utterance)
        }

        override func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
            stopCount += 1
            return canStop
        }
    }

    private final class LiveSession: SpeechAudioSession {
        let released: XCTestExpectation

        init(released: XCTestExpectation) { self.released = released }

        func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
            try AVAudioSession.sharedInstance().setCategory(category, mode: mode, options: options)
        }

        func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
            try AVAudioSession.sharedInstance().setActive(active, options: options)
            if !active {
                XCTAssertEqual(options, .notifyOthersOnDeactivation)
                released.fulfill()
            }
        }
    }

    private final class StartObserver: NSObject, AVSpeechSynthesizerDelegate {
        let helper: AudioHelper
        let started: XCTestExpectation
        init(helper: AudioHelper, started: XCTestExpectation) {
            self.helper = helper
            self.started = started
        }
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
            started.fulfill()
        }
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            helper.speechSynthesizer(synthesizer, didFinish: utterance)
        }
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
            helper.speechSynthesizer(synthesizer, didCancel: utterance)
        }
    }

    // Two barriers cover the deferred idle check without sleeps or audio timing.
    private func drain(_ helper: AudioHelper) {
        helper.speechQueue.sync {}
        helper.speechQueue.sync {}
    }

    private func makeHelper() -> (AudioHelper, Synthesizer, Session) {
        let synth = Synthesizer()
        let session = Session()
        return (AudioHelper(synthesizer: synth, speechSession: .init(audioSession: session)), synth, session)
    }

    func testSessionRemainsInactiveUntilSpeechAndReleasesAfterFinish() {
        let (helper, synth, session) = makeHelper()
        XCTAssertTrue(session.transitions.isEmpty)
        XCTAssertTrue(session.categories.isEmpty)
        synth.onSpeak = { XCTAssertEqual(session.transitions.map(\.0), [true]) }
        helper.speak("Hello", canBeMuted: true)
        drain(helper)
        XCTAssertEqual(session.categories.first?.0, .playback)
        XCTAssertEqual(session.categories.first?.1, .voicePrompt)
        XCTAssertEqual(session.categories.first?.2, [.duckOthers])
        XCTAssertFalse(session.categories[0].2.contains(.interruptSpokenAudioAndMixWithOthers))
        helper.speechSynthesizer(synth, didFinish: synth.utterances[0])
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
        XCTAssertEqual(session.transitions.last?.1, .notifyOthersOnDeactivation)
    }

    func testRapidQueuedUtterancesKeepOneActivationUntilLastFinish() {
        let (helper, synth, session) = makeHelper()
        for index in 0..<30 { helper.speak("Word \(index)", canBeMuted: true) }
        drain(helper)
        XCTAssertEqual(synth.utterances.count, 30)
        for utterance in synth.utterances.dropLast() {
            helper.speechSynthesizer(synth, didFinish: utterance)
        }
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true])
        helper.speechSynthesizer(synth, didFinish: synth.utterances.last!)
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
    }

    func testCancellationCallbackReleasesSession() {
        let (helper, synth, session) = makeHelper()
        helper.speak("Hello", canBeMuted: true)
        drain(helper)
        helper.speechSynthesizer(synth, didCancel: synth.utterances[0])
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
    }

    func testCancellingQueueDoesNotRequireCallbacksForUnstartedUtterances() {
        let (helper, synth, session) = makeHelper()
        helper.speak("First", canBeMuted: true)
        helper.speak("Second", canBeMuted: true)
        drain(helper)
        helper.cancelSpeech()
        drain(helper)
        XCTAssertEqual(synth.stopCount, 1)
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
    }

    func testImmediateReplacementAndLateDuplicateCallbacksCannotReleaseNewSpeech() {
        let (helper, synth, session) = makeHelper()
        helper.speak("Old", canBeMuted: true)
        drain(helper)
        let old = synth.utterances[0]
        // Enqueue both operations before the serial queue can process cancellation.
        helper.speechQueue.suspend()
        helper.cancelSpeech()
        helper.speak("Replacement", canBeMuted: true)
        helper.speechQueue.resume()
        drain(helper)
        helper.speechSynthesizer(synth, didCancel: old)
        helper.speechSynthesizer(synth, didFinish: old)
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true])
        helper.speechSynthesizer(synth, didFinish: synth.utterances[1])
        helper.speechSynthesizer(synth, didCancel: synth.utterances[1])
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
    }

    func testNewSelectionAlreadySubmittedAtCompletionKeepsSessionActive() {
        let (helper, synth, session) = makeHelper()
        helper.speak("First", canBeMuted: true)
        drain(helper)
        helper.speechQueue.suspend()
        helper.speechSynthesizer(synth, didFinish: synth.utterances[0])
        helper.speak("Second", canBeMuted: true)
        helper.speechQueue.resume()
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true])
        helper.speechSynthesizer(synth, didFinish: synth.utterances[1])
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
    }

    func testSeparateHelpersShareOwnershipUntilBothAreFinished() {
        let session = Session()
        let ownership = AudioHelper.SpeechSession(audioSession: session)
        let firstSynth = Synthesizer()
        let secondSynth = Synthesizer()
        let first = AudioHelper(synthesizer: firstSynth, speechSession: ownership)
        let second = AudioHelper(synthesizer: secondSynth, speechSession: ownership)
        first.speak("AAC", canBeMuted: true)
        second.speak("Preview", canBeMuted: true)
        drain(first)
        first.cancelSpeech()
        drain(first)
        XCTAssertEqual(session.transitions.map(\.0), [true])
        second.speechSynthesizer(secondSynth, didFinish: secondSynth.utterances[0])
        drain(second)
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
    }

    func testConfigurationAndActivationErrorsStillAttemptSpeechAndRelease() {
        let (helper, synth, session) = makeHelper()
        session.failCategory = true
        session.failActivation = true
        helper.speak("Important communication", canBeMuted: true)
        drain(helper)
        XCTAssertEqual(synth.utterances.count, 1)
        helper.speechSynthesizer(synth, didFinish: synth.utterances[0])
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
        session.failCategory = false
        session.failActivation = false
        helper.speak("Retry", canBeMuted: true)
        drain(helper)
        XCTAssertEqual(session.categories.count, 2)
        helper.speechSynthesizer(synth, didFinish: synth.utterances[1])
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false, true, false])
    }

    func testDeactivationFailureIsRetriedAtNextIdleCallback() {
        let (helper, synth, session) = makeHelper()
        helper.speak("Hello", canBeMuted: true)
        drain(helper)
        session.failDeactivation = true
        helper.speechSynthesizer(synth, didFinish: synth.utterances[0])
        drain(helper)
        session.failDeactivation = false
        helper.speechSynthesizer(synth, didCancel: synth.utterances[0])
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false, false])
    }

    func testBackgroundingCancelsAndReleasesAndForegroundSpeechCanRestart() {
        let (helper, synth, session) = makeHelper()
        helper.speak("Background", canBeMuted: true)
        drain(helper)
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
        helper.speak("Foreground", canBeMuted: true)
        drain(helper)
        helper.speechSynthesizer(synth, didFinish: synth.utterances[1])
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false, true, false])
        XCTAssertEqual(session.categories.count, 1)
    }

    func testFailedStopDoesNotReleaseSpeechStillInProgress() {
        let (helper, synth, session) = makeHelper()
        helper.speak("Hello", canBeMuted: true)
        drain(helper)
        synth.canStop = false
        helper.cancelSpeech()
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true])
        helper.speechSynthesizer(synth, didFinish: synth.utterances[0])
        drain(helper)
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
    }

    func testReleasingHelperDuringSpeechReleasesItsSessionOwnership() {
        let session = Session()
        let ownership = AudioHelper.SpeechSession(audioSession: session)
        let synth = Synthesizer()
        var helper: AudioHelper? = AudioHelper(synthesizer: synth, speechSession: ownership)
        helper!.speak("Hello", canBeMuted: true)
        drain(helper!)
        helper = nil
        ownership.queue.sync {}
        XCTAssertEqual(session.transitions.map(\.0), [true, false])
    }

    @MainActor func testActualSynthesizerReleasesSessionAfterQueuedSpeech() async {
        let released = expectation(description: "Live speech queue released audio session")
        released.assertForOverFulfill = true
        let helper = AudioHelper(synthesizer: AVSpeechSynthesizer(), speechSession: .init(audioSession: LiveSession(released: released)))
        helper.speak("One", canBeMuted: true, language: "en-GB")
        helper.speak("Two", canBeMuted: true, language: "en-GB")
        await fulfillment(of: [released], timeout: 20)
        drain(helper)
    }

    @MainActor func testActualSynthesizerCancellationAndReplacementReleaseSession() async {
        let released = expectation(description: "Live replacement speech released audio session")
        released.assertForOverFulfill = true
        let helper = AudioHelper(synthesizer: AVSpeechSynthesizer(), speechSession: .init(audioSession: LiveSession(released: released)), makeSynthesizer: AVSpeechSynthesizer.init)
        helper.speak(String(repeating: "Hello. ", count: 30), canBeMuted: true, language: "en-GB")
        drain(helper)
        helper.speechQueue.suspend()
        helper.cancelSpeech()
        helper.speak("Replacement", canBeMuted: true, language: "en-GB")
        helper.speechQueue.resume()
        await fulfillment(of: [released], timeout: 20)
        drain(helper)
    }

    @MainActor func testActualSpeechCancelledAfterStartingAndImmediatelyReplaced() async {
        let started = expectation(description: "Native utterance started")
        let released = expectation(description: "Session released after replacement")
        released.assertForOverFulfill = true
        let synth = AVSpeechSynthesizer()
        let helper = AudioHelper(synthesizer: synth, speechSession: .init(audioSession: LiveSession(released: released)), makeSynthesizer: AVSpeechSynthesizer.init)
        let observer = StartObserver(helper: helper, started: started)
        synth.delegate = observer
        helper.speak(String(repeating: "Hello. ", count: 30), canBeMuted: true, language: "en-GB")
        await fulfillment(of: [started], timeout: 10)
        helper.speechQueue.suspend()
        helper.cancelSpeech()
        helper.speak("Replacement", canBeMuted: true, language: "en-GB")
        helper.speechQueue.resume()
        await fulfillment(of: [released], timeout: 20)
        drain(helper)
        withExtendedLifetime(observer) {}
    }

    @MainActor func testRecordedSelectionReleasesSessionAfterPlayback() async throws {
        let released = expectation(description: "Recorded AAC released audio session")
        released.assertForOverFulfill = true
        let helper = AudioHelper(synthesizer: AVSpeechSynthesizer(), speechSession: .init(audioSession: LiveSession(released: released)))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
        defer { try? FileManager.default.removeItem(at: url) }
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1))
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 2205))
        buffer.frameLength = buffer.frameCapacity
        buffer.floatChannelData![0].initialize(repeating: 0, count: Int(buffer.frameLength))
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
        }
        helper.playAudio(contentsOf: url, canBeMuted: true)
        await fulfillment(of: [released], timeout: 10)
        drain(helper)
    }
}
