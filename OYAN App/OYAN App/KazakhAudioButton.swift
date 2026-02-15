//
//  KazakhAudioButton.swift
//  OYAN App
//
//  API Assignment (see API_ARCHITECTURE.md): AZURE is responsible for TTS.
//  Plays Kazakh text-to-speech via Supabase Edge Function (get-kazakh-audio).
//  The Edge Function uses Microsoft Azure Speech Services for Kazakh TTS.
//  Uses .playback so audio plays when device is silent.
//

import SwiftUI
import AVFoundation

private let kazakhAudioURL = URL(string: "https://porfjjvcnixghoxnbbdt.supabase.co/functions/v1/get-kazakh-audio")!

struct KazakhAudioButton: View {
    let text: String

    /// Keeps the current player alive so playback isn't cut off when the static play(text:) closure exits.
    private static var sharedPlayer: AVAudioPlayer?

    @State private var isPlaying = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var player: AVAudioPlayer?

    var body: some View {
        Button {
            Task { await playAudio() }
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 72, height: 72)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#f9a63c")))
        }
        .buttonStyle(.plain)
        .disabled(isLoading || text.isEmpty)
        .alert("Audio", isPresented: $showError) {
            Button("OK") { showError = false; errorMessage = "" }
        } message: {
            Text(errorMessage)
        }
    }

    private func playAudio() async {
        guard !text.isEmpty else { return }
        isLoading = true
        showError = false
        errorMessage = ""
        defer { isLoading = false }

        do {
            var request = URLRequest(url: kazakhAudioURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(SupabaseManager.shared.anonKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(["text": text])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                await MainActor.run { errorMessage = "Invalid response"; showError = true }
                return
            }
            guard (200...299).contains(http.statusCode) else {
                await MainActor.run { errorMessage = "Server error: \(http.statusCode)"; showError = true }
                return
            }
            guard !data.isEmpty else {
                await MainActor.run { errorMessage = "No audio data received"; showError = true }
                return
            }

            try await MainActor.run {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                player = try AVAudioPlayer(data: data)
                player?.prepareToPlay()
                player?.play()
                isPlaying = true
                // Reset when playback finishes (approximate for UI)
                DispatchQueue.main.asyncAfter(deadline: .now() + (player?.duration ?? 2)) {
                    isPlaying = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Static playback (e.g. for alphabet letter taps)
    /// Fetches Kazakh TTS for the given text and plays it. Uses .playback session so audio plays when silent.
    static func play(text: String) async {
        guard !text.isEmpty else { return }
        do {
            var request = URLRequest(url: kazakhAudioURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(SupabaseManager.shared.anonKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(["text": text])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), !data.isEmpty else { return }

            try await MainActor.run {
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try? AVAudioSession.sharedInstance().setActive(true)
                let player = try? AVAudioPlayer(data: data)
                guard let player = player else { return }
                sharedPlayer = player
                player.prepareToPlay()
                player.play()
                let duration = player.duration
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    sharedPlayer = nil
                }
            }
        } catch { /* silent fail for background playback */ }
    }
}
