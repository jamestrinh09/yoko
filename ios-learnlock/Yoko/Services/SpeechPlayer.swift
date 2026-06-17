//
//  SpeechPlayer.swift
//  Yoko
//
//  Lightweight on-device text-to-speech used by phonics questions so children
//  identify words by ear. Uses AVSpeechSynthesizer — no network or assets.
//

import AVFoundation

@MainActor
final class SpeechPlayer {
    static let shared = SpeechPlayer()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    /// Speaks the given text aloud, stopping any in-progress utterance first.
    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = 0.38
        utterance.pitchMultiplier = 1.15
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}
