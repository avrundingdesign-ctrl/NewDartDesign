import Foundation
import AVFoundation
import Combine

/// Wrapper um AVSpeechSynthesizer für deutsche TTS mit Mute-Option.
@MainActor
final class SpeechService: NSObject, ObservableObject {

    private let synthesizer = AVSpeechSynthesizer()
    @Published var isMuted: Bool = false
    @Published private(set) var isSpeaking: Bool = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Nuanciert: stummgeschaltet wird der Call schlicht ignoriert.
    func speak(_ text: String, rate: Float = 0.45) {
        guard !isMuted else { return }
        prepareAudio()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    /// Sofort abbrechen (z.B. wenn Bust kommt).
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    func toggleMute() { isMuted.toggle(); if isMuted { stop() } }

    private func prepareAudio() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.duckOthers, .defaultToSpeaker])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
