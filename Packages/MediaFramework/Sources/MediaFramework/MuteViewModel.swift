//
//  MuteViewModel.swift
//  
//
//  Created by Andy on 24/08/2024.
//

#if canImport(Combine)
import Combine
#endif

import Foundation
import Mute
import AVFoundation

@available(iOS 13.0, *)
class MuteViewModel : ObservableObject {
    @Published var isPromptDismissed: Bool = false
    @Published var showMutePrompt: Bool = false

    private var isMuted: Bool = false
    private var volume: Float = 0

    var audioSession: AVAudioSession!
    var volumeObservation: NSKeyValueObservation?
    
    init() {
        setupMuteDetector()
        addVolumeObserver()
    }
    
    deinit {
        removeVolumeObserver()
    }
    
    func setupMuteDetector() {

        // Notify every 2 seconds
        Mute.shared.checkInterval = 2.0
        
        // Always notify on interval
        Mute.shared.alwaysNotify = true
        
        // Update label when notification received
        Mute.shared.notify = { newMuteValue in
            //let newMuteValue = true
            if newMuteValue != self.isMuted {
                self.isMuted = newMuteValue
                self.recalc()
            }
        }
    }
    
    func recalc() {
        let shouldShowPrompt = (self.isMuted || self.volume == 0)
        if !shouldShowPrompt {
            self.showMutePrompt = false
        }
        else {
            if !isPromptDismissed {
                self.showMutePrompt = true
            }
        }
    }
    
    func dismissPrompt() {
        self.isPromptDismissed = true
        self.showMutePrompt = false
    }
    
    func addVolumeObserver() {
        // Set up AVAudioSession
        audioSession = AVAudioSession.sharedInstance()
        self.volume = audioSession.outputVolume
        self.recalc()
        
        // Observe changes to the outputVolume
        volumeObservation = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] (audioSession, change) in
            if let newVolume = change.newValue {
                self?.volumeDidChange(to: newVolume)
            }
        }
    }
    
    func removeVolumeObserver() {
        // Cleanup observation
        volumeObservation?.invalidate()
    }
                                               
    func volumeDidChange(to newVolume: Float) {
        if self.volume != newVolume {
            self.volume = newVolume
            recalc()
        }
    }
    
}
