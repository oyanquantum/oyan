//
//  ChatViewModel.swift
//  OYAN App
//
//  View model for the Chat screen. Manages messages, input, loading.
//  Persists messages to Supabase. Uses chat-assistant (Gemini + KazLLM).
//

import Foundation
import Combine

/// Free chat limit: user can send up to this many messages before being prompted to pay.
let chatMessageLimit = 3

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var isLoadingHistory: Bool = false
    @Published var showUsageLimitAlert: Bool = false

    private let service = GeminiService.shared

    var userMessageCount: Int { messages.filter { $0.role == .user }.count }

    /// Prior lessons summary for level adaptation. Set before sending.
    var priorLessonsSummary: String?
    /// User's UI language: "en" or "ru" — used only for grammar-help exceptions.
    var userLanguage: String = "en"
    /// Current user ID for loading/saving. Set before load or send.
    var userId: UUID?

    /// Load chat history from Supabase. Call when view appears.
    func loadIfNeeded() async {
        guard let userId = userId else { return }
        guard messages.isEmpty else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        do {
            let loaded = try await SupabaseService.shared.fetchChatMessages(userId: userId)
            messages = loaded
        } catch {
            // Silently ignore; user starts fresh
        }
    }

    private func saveMessage(_ message: ChatMessage) async {
        guard let userId = userId else { return }
        try? await SupabaseService.shared.saveChatMessage(userId: userId, role: message.role, text: message.text)
    }

    func send() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }

        if userMessageCount >= chatMessageLimit {
            showUsageLimitAlert = true
            return
        }

        let userMessage = ChatMessage(role: .user, text: trimmed)
        messages.append(userMessage)
        await saveMessage(userMessage)
        inputText = ""
        isLoading = true

        let payloads = messages.map { ChatMessagePayload(role: $0.role.rawValue, text: $0.text) }

        do {
            let response = try await service.chat(
                messages: payloads,
                priorLessonsSummary: priorLessonsSummary,
                userLanguage: userLanguage
            )
            let assistantMessage = ChatMessage(role: .assistant, text: response)
            messages.append(assistantMessage)
            await saveMessage(assistantMessage)
        } catch {
            let errorMessage = ChatMessage(
                role: .assistant,
                text: "Кешіріңіз, қате орын алды. Тағы көріңіз."
            )
            messages.append(errorMessage)
            // Don't persist error messages
        }

        isLoading = false
    }
}
