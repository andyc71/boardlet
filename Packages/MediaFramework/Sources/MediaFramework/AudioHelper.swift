//
//  AudioHelper.swift
//  My Family
//
//  Created by Andy Clynes on 22/01/2017.
//  Copyright © 2017 Andy Clynes. All rights reserved.
//

import AVFoundation
import UIKit
@preconcurrency import LogFramework


@objc public protocol AudioHelperDelegate : NSObjectProtocol {

    func audioPlayerDidFinishPlaying(_ player: AudioHelper, url: URL?, tag: String?, successfully flag: Bool)

    func isAudioMuted(_ player: AudioHelper) -> Bool
    
    func getVolume(_ player: AudioHelper) -> Float
}

extension AVAudioPlayer /*: AssociatedObjects*/ {
    
    static var tagProperty = "com.bluebay.AVAudioPlayer.tag"
    /*
    var tag: String? {
        get {
            return associatedObject(for: AVAudioPlayer.tagProperty)
        }
        set {
            setAssociatedObject(newValue, for: AVAudioPlayer.tagProperty, policy: .strong)
        }
            
    }*/
    
    
    private struct AssociatedKey {
        static var viewExtension: UInt8 = 0
        }

        var tag: String? {
            get {
                return getAssociatedObject(object: self, associativeKey: &AssociatedKey.viewExtension)
            }

            set {
                if let value = newValue {
                    setAssociatedObject(object: self, value: value, associativeKey: &AssociatedKey.viewExtension, policy: objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
            }
        }
    
    
    
    

    
}

class QueuedAudioFile {
    var url: URL
    var tag: String?
    var canBeMuted: Bool
    
    init(url: URL, tag: String?, canBeMuted: Bool) {
        self.url = url
        self.tag = tag
        self.canBeMuted = canBeMuted
    }
}

protocol SpeechAudioSession {
    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
}

extension AVAudioSession: SpeechAudioSession {}

public class AudioHelper: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    
    public static var audioDirectoryURL: URL?
 
    var audioPlayers = Set<AVAudioPlayer>()

    var audioQueue = [QueuedAudioFile]()
    var currentAudioPlayerIndex = 0

    weak var delegate: AudioHelperDelegate?
    var preserveAfterPlayback = false
    
    public var isLoopedPlaylist: Bool = false {
        didSet {
            //Turn off looping in the audio players because we will do it.
            for audioPlayer in audioPlayers {
                audioPlayer.numberOfLoops = 0
            }
        }
    }
    
    private var isMuted: Bool {
        get {
            guard let d = delegate else {
                return false
            }
            let retval = d.isAudioMuted(self) 
            return retval
        }
    }
    
    var completionHandlers = [URL: (()->Void)]()

    /*
    public override init() {
        super.init()
    }*/
    
    deinit {
        if let backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
        let synthesizer = synth
        let session = speechSession
        let utterances = pendingUtterances
        let players = audioPlayers
        session.queue.async {
            synthesizer.delegate = nil
            synthesizer.stopSpeaking(at: .immediate)
            session.pendingUtterances.subtract(utterances)
            for player in players {
                player.stop()
                session.pendingPlayers.remove(ObjectIdentifier(player))
            }
            session.deactivateAudioSessionIfIdle()
        }
        for player in audioPlayers {
            player.delegate = nil
        }
    }
    
    public init(delegate: AudioHelperDelegate? = nil, preserveAfterPlayback: Bool = false) {
        self.synth = AVSpeechSynthesizer()
        self.makeSynthesizer = AVSpeechSynthesizer.init
        self.speechSession = Self.sharedSpeechSession
        self.delegate = delegate
        self.preserveAfterPlayback = preserveAfterPlayback
        super.init()
        synth.delegate = self
        observeBackgrounding()
    }

    // Injection keeps lifecycle tests independent of device audio and installed voices.
    init(synthesizer: AVSpeechSynthesizer, speechSession: SpeechSession, makeSynthesizer: (() -> AVSpeechSynthesizer)? = nil) {
        self.synth = synthesizer
        self.makeSynthesizer = makeSynthesizer ?? { synthesizer }
        self.speechSession = speechSession
        super.init()
        synth.delegate = self
        observeBackgrounding()
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    private func getThemeOverride(for resourceName: String) -> URL? {
        guard let themeDir = AudioHelper.audioDirectoryURL else {
            return nil
        }
        let url = themeDir.appendingPathComponent(resourceName, isDirectory: false)
        if !fileExists(atPath: url.path) {
            return nil
        }
        return url
    }
    
    private func fileExists(atPath path: String) -> Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: path)
    }

    private func getDocumentOverride(for resourceName: String) -> URL? {
        let docDir = getDocumentsDirectory()
        let url = docDir.appendingPathComponent(resourceName, isDirectory: false)
        if !fileExists(atPath: url.path) {
            return nil
        }
        return url
    }

    public func playAudioFromResource(resourceName: String, tag: String? = nil, queue: Bool = false, loop: Bool = false, canBeMuted: Bool) {
        
        
        //Check for file level override within a theme.
        var url = getThemeOverride(for: resourceName)
        if url == nil {
            url = getDocumentOverride(for: resourceName)
        }
        if url == nil {
            guard let resourceURL = Bundle.main.url(forResource: resourceName, withExtension: nil) else {
                logger.logWarning(.audio, "No matching audio for \(resourceName)")
                return
            }
            guard FileManager.default.fileExists(atPath: resourceURL.path) else {
                logger.logWarning(.audio, "No matching audio for \(resourceName)")
                return
            }
            url = resourceURL
        }
        
        playAudio(contentsOf: url!, tag: tag, queue: queue, loop: loop, canBeMuted: canBeMuted)
    }
    
    private var synth: AVSpeechSynthesizer
    private let makeSynthesizer: () -> AVSpeechSynthesizer
    // All helpers (AAC and voice previews) share ownership of the application session.
    // State and synthesizer operations are confined to the same serial queue.
    final class SpeechSession {
        let audioSession: SpeechAudioSession
        // Own all speech submissions, completion bookkeeping, and session transitions here.
        // setActive is synchronous on iOS 16.6, so keep it off the UI thread.
        let queue = DispatchQueue(label: "MediaFramework.AudioHelper.speech")
        var pendingUtterances = Set<ObjectIdentifier>()
        var pendingPlayers = Set<ObjectIdentifier>()
        private var isAudioSessionConfigured = false
        private var isAudioSessionActive = false

        func activateAudioSession() {
            if !isAudioSessionConfigured {
                do {
                    try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
                    isAudioSessionConfigured = true
                } catch {
                    logger.logError(.audio, "Could not configure speech audio session", error)
                }
            }
            guard !isAudioSessionActive else { return }
            // Release our session after speech even if the explicit activation fails:
            // AVSpeechSynthesizer may activate it while attempting playback.
            isAudioSessionActive = true
            do {
                try audioSession.setActive(true, options: [])
            } catch {
                logger.logError(.audio, "Could not activate speech audio session", error)
            }
        }

        func deactivateAudioSessionIfIdle() {
            guard pendingUtterances.isEmpty, pendingPlayers.isEmpty, isAudioSessionActive else { return }
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                isAudioSessionActive = false
            } catch {
                // Keep the active flag so the next idle transition can retry release.
                logger.logError(.audio, "Could not deactivate speech audio session", error)
            }
        }

        init(audioSession: SpeechAudioSession) {
            self.audioSession = audioSession
        }
    }

    private static let sharedSpeechSession = SpeechSession(audioSession: AVAudioSession.sharedInstance())
    private let speechSession: SpeechSession
    var speechQueue: DispatchQueue { speechSession.queue }
    private var pendingUtterances = Set<ObjectIdentifier>()
    private var backgroundObserver: NSObjectProtocol?

    private func observeBackgrounding() {
        // Boardlet has no background-audio capability. Release before suspension,
        // rather than waiting for a completion callback that may arrive on resume.
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil
        ) { [weak self] _ in
            self?.cancelSpeech()
            self?.stop()
        }
    }

    private func completeSpeech(_ utterance: AVSpeechUtterance) {
        speechQueue.async {
            self.pendingUtterances.remove(ObjectIdentifier(utterance))
            self.speechSession.pendingUtterances.remove(ObjectIdentifier(utterance))
            // Check again after already submitted selections/cancellation replacements.
            self.speechQueue.async { self.speechSession.deactivateAudioSessionIfIdle() }
        }
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completeSpeech(utterance)
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        completeSpeech(utterance)
    }

    public func cancelSpeech() {
        speechQueue.async {
            guard !self.pendingUtterances.isEmpty else {
                self.speechQueue.async { self.speechSession.deactivateAudioSessionIfIdle() }
                return
            }
            // stopSpeaking clears the synthesizer's entire queue, but queued utterances
            // aren't guaranteed individual cancellation callbacks.
            let stopped = self.synth.stopSpeaking(at: .immediate)
            if stopped || !self.synth.isSpeaking {
                // During voice preparation, stopSpeaking can return false while
                // isSpeaking is false. Discard that queue too, so pending speech
                // is cancelled and an immediate replacement can start normally.
                self.synth.delegate = nil
                self.synth = self.makeSynthesizer()
                self.synth.delegate = self
                self.speechSession.pendingUtterances.subtract(self.pendingUtterances)
                self.pendingUtterances.removeAll()
            }
            self.speechQueue.async { self.speechSession.deactivateAudioSessionIfIdle() }
        }
    }

    // Recorded AAC selections use the same session as synthesized speech.
    private func playAudioPlayer(_ player: AVAudioPlayer) {
        let volume = delegate?.getVolume(self)
        speechQueue.async {
            self.speechSession.pendingPlayers.insert(ObjectIdentifier(player))
            self.speechSession.activateAudioSession()
            if let volume {
                player.setVolume(volume, fadeDuration: 0)
            }
            if !player.play() {
                self.audioPlayerDidFinishPlaying(player, successfully: false)
            }
        }
    }

    public static func defaultVoice(for language: String) -> AVSpeechSynthesisVoice? {
        if let voice = AVSpeechSynthesisVoice(language: language) {
            return voice
        }

        let baseLanguage = language.split(separator: "-").first.map(String.init) ?? language
        if let voice = AVSpeechSynthesisVoice(language: baseLanguage) {
            return voice
        }

        if let availableVoice = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language.split(separator: "-").first.map(String.init) == baseLanguage
        }) {
            return AVSpeechSynthesisVoice(language: availableVoice.language) ?? availableVoice
        }

        return AVSpeechSynthesisVoice(language: nil)
    }
    
    // TODO: Handle canBeMuted.
    public func speak(_ string: String, canBeMuted: Bool, voiceIdentifier: String? = nil, language: String? = nil) {
        logger.logDebug(LogCategory.audio, "Speak audio: \(string) ")
        let utterance = AVSpeechUtterance(string: string)
        
        //Languages: https://developer.apple.com/forums/thread/70390
        
        //Print identifiers with:  po AVSpeechSynthesisVoice.speechVoices()
        
        if let voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        }
        else if let language {
            utterance.voice = Self.defaultVoice(for: language)
        }
        else if let voice = AVSpeechSynthesisVoice.speechVoices().first(where: {$0.name.contains("Noelle")}) {
            utterance.voice = voice
        }
        else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        }
        
        //Also po AVSpeechSynthesisVoice.speechVoices()
        //utterance.rate = AVSpeechUtteranceMinimumSpeechRate + ((AVSpeechUtteranceDefaultSpeechRate - AVSpeechUtteranceMinimumSpeechRate) * 0.9)
        //utterance.pitchMultiplier = 2.0
        if let delegate = self.delegate {
            utterance.volume = delegate.getVolume(self)
        }

        speechQueue.async {
            self.pendingUtterances.insert(ObjectIdentifier(utterance))
            self.speechSession.pendingUtterances.insert(ObjectIdentifier(utterance))
            self.speechSession.activateAudioSession()
            self.synth.speak(utterance)
        }
    }
    
    public func playAudio(contentsOf: URL, tag: String? = nil, queue: Bool = false, loop: Bool = false, canBeMuted: Bool) {
        do {
            logger.logDebug(LogCategory.audio, "PlayAudio - \(contentsOf): queue?: \(queue) loop?: \(loop)")

            if queue && audioPlayers.count > 0 {
                queueAudioFile( contentsOf, tag: tag, canBeMuted: canBeMuted )
                return
            }
            
            let player = try AVAudioPlayer(contentsOf: contentsOf)
            player.tag = tag
            if loop {
                player.numberOfLoops = 10
            }
            player.delegate = self
            audioPlayers.insert(player)

            if canBeMuted && isMuted {
                audioPlayerDidFinishPlaying(player, successfully: true)
            }
            else {
                playAudioPlayer(player)
            }
                
        } catch {
            logger.logError(LogCategory.audio, "PlayAudio - could not load file \(contentsOf)", error)
            //call the delegate so the caller can behave as if the audio completed.
            let player = AVAudioPlayer()
            audioPlayers.insert(player)
            audioPlayerDidFinishPlaying(player, successfully: false)
        }
    }
    
    public func prepareAudio(contentsOf: URL) {
        do {
            logger.logDebug(LogCategory.audio, "PrepareAudio - \(contentsOf)")
            let audioPlayer = try AVAudioPlayer(contentsOf: contentsOf)
            audioPlayer.delegate = self
            audioPlayers.insert(audioPlayer)
            audioPlayer.prepareToPlay()
        } catch {
            logger.logError(LogCategory.audio, "PrepareAudio - could not load file \(contentsOf)")
        }
    }
    
    public func prepareAudioFromResource(resourceName: String) {
        
        let url = URL(fileReferenceLiteralResourceName: resourceName)
        prepareAudio(contentsOf: url)
    }
    
    
    
    public func playPreparedAudio() {
        logger.logDebug(LogCategory.audio, "PlayPreparedAudio")
        if audioPlayers.count != 1 {
            logger.logError(LogCategory.audio, "PrepareAudio - Audio player not prepared \(audioPlayers.count)")
            return
        }
        let player  = audioPlayers.first!
        //if audioPlayer.isPlaying {
          //  print("playPreparedAudio - stop")
            //audioPlayer.stop()
        //}
        
        if isMuted {
            audioPlayerDidFinishPlaying(player, successfully: true)
        }
        else {
            playAudioPlayer(player)
        }
    }
    

    
    public func queueAudioFile(_ contentsOf: URL, tag: String? = nil, canBeMuted: Bool) {
        logger.logDebug(LogCategory.audio, "QueueAudioFile - \(contentsOf)")
        audioQueue.append( QueuedAudioFile(url: contentsOf, tag: tag, canBeMuted: canBeMuted) )
    }
    
    public func stop() {
        let players = audioPlayers
        audioPlayers.removeAll()
        speechQueue.async {
            for audioPlayer in players {
                if audioPlayer.isPlaying {
                    audioPlayer.stop()
                    self.audioPlayerDidFinishPlaying(audioPlayer, successfully: true)
                } else {
                    self.speechSession.pendingPlayers.remove(ObjectIdentifier(audioPlayer))
                }
            }
            self.speechQueue.async { self.speechSession.deactivateAudioSessionIfIdle() }
        }
    }
    
    public func pause() {
        let players = audioPlayers
        speechQueue.async {
            for audioPlayer in players {
                audioPlayer.pause()
                self.speechSession.pendingPlayers.remove(ObjectIdentifier(audioPlayer))
            }
            self.speechSession.deactivateAudioSessionIfIdle()
        }
    }
    
    public func resume() {
        for player in audioPlayers {
            playAudioPlayer(player)
        }
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        speechQueue.async {
            self.speechSession.pendingPlayers.remove(ObjectIdentifier(player))
            self.speechQueue.async { self.speechSession.deactivateAudioSessionIfIdle() }
        }
        //logger.categoriesToLog = [.audio]
        //logger.logLevel = .debug
        
        let url = player.url
        let tag = player.tag
        
        logger.logDebug(.audio, "Audio finished playing \(String(describing: url))")
                
        if !preserveAfterPlayback {
            audioPlayers.remove(player)
        }

        if let d = delegate {
            d.audioPlayerDidFinishPlaying(self, url: url, tag: tag, successfully: flag)
        }

        if url != nil {
            let completionHandler = completionHandlers[url!]
            if completionHandler != nil {
                completionHandler!()
                if (!preserveAfterPlayback) {
                    completionHandlers[url!] = nil
                }
                
            }
        }
 
        playNextTrack()
     
    }
    
    public func playNextTrack() {
        currentAudioPlayerIndex += 1
        if currentAudioPlayerIndex >= audioQueue.count {
            currentAudioPlayerIndex = 0
            if isLoopedPlaylist {
                playQueue()
            }
        }
        else {
            playQueue()
        }
    }
    
    public func playQueue() {
        if audioPlayers.count==0 && audioQueue.count > 0 {
            let item = audioQueue[currentAudioPlayerIndex]
            //audioQueue.remove(at: 0)
            playAudio(contentsOf: item.url, tag: item.tag, canBeMuted: item.canBeMuted)
        }
    }
    
    public func isPlaying() -> Bool {
        if audioPlayers.count == 0 {
            return false
        }
        
        for player in audioPlayers {
            if player.isPlaying {
                return true
            }
        }
        
        return false
        
    }
    
    /*
    public func reduceVolume() {
        for player in audioPlayers {
            player.volume = 0.5
        }
        
    }*/

    public func setVolume(_ volumeLevel: Float) {
        for player in audioPlayers {
            player.volume = volumeLevel
        }
    }

    
    public func normalVolume() {
        for player in audioPlayers {
            player.volume = 1.0
        }

    }
    
    
    

}
