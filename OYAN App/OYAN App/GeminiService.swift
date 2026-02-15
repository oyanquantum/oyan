//
//  GeminiService.swift
//  OYAN App
//
//  API Assignment (see API_ARCHITECTURE.md): GEMINI generates chat responses.
//  Chat uses chat-assistant (Gemini + KazLLM, Kazakh-only). Other uses via gemini-generator.
//

import Foundation

struct ChatMessagePayload: Encodable {
    let role: String
    let text: String
}

final class GeminiService {
    static let shared = GeminiService()

    private let geminiGeneratorURL = "https://porfjjvcnixghoxnbbdt.supabase.co/functions/v1/gemini-generator"
    private let chatAssistantURL = "https://porfjjvcnixghoxnbbdt.supabase.co/functions/v1/chat-assistant"
    private let timeout: TimeInterval = 90

    private init() {}

    /// Chat with the Kazakh tutor. Tries chat-assistant first; falls back to gemini-generator if unavailable.
    func chat(
        messages: [ChatMessagePayload],
        priorLessonsSummary: String? = nil,
        userLanguage: String = "en"
    ) async throws -> String {
        // Try chat-assistant first (Gemini + KazLLM, Kazakh-only)
        do {
            return try await chatViaAssistant(messages: messages, priorLessonsSummary: priorLessonsSummary, userLanguage: userLanguage)
        } catch {
            // Fallback: use gemini-generator with crafted prompt (works without deploying chat-assistant)
            return try await chatViaGenerator(messages: messages, priorLessonsSummary: priorLessonsSummary, userLanguage: userLanguage)
        }
    }

    private func chatViaAssistant(
        messages: [ChatMessagePayload],
        priorLessonsSummary: String?,
        userLanguage: String
    ) async throws -> String {
        guard let url = URL(string: chatAssistantURL) else { throw GeminiServiceError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        request.setValue("Bearer \(SupabaseManager.shared.anonKey)", forHTTPHeaderField: "Authorization")
        var body: [String: Any] = ["messages": messages.map { ["role": $0.role, "text": $0.text] }]
        if let s = priorLessonsSummary, !s.isEmpty { body["prior_lessons_summary"] = s }
        body["user_language"] = userLanguage
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = parseErrorMessage(from: data) ?? "HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)"
            throw GeminiServiceError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: msg)
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = json["text"] as? String, !text.isEmpty {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw GeminiServiceError.emptyResponse
    }

    private func chatViaGenerator(
        messages: [ChatMessagePayload],
        priorLessonsSummary: String?,
        userLanguage: String
    ) async throws -> String {
        let levelNote = priorLessonsSummary.map { "The user has completed these lessons:\n\($0)\n\nUse vocabulary appropriate for their level." }
            ?? "Assume the user is a beginner. Use simple Kazakh."
        var conv: [String] = []
        for m in messages {
            let label = m.role == "user" ? "User" : "Assistant"
            conv.append("\(label): \(m.text)")
        }
        let explainLang = userLanguage == "ru" ? "Russian" : "English"
        let prompt = """
        You are a Kazakh language tutor in OYAN. STRICT RULES:
        1) NORMAL CHAT: When replying in Kazakh, use MAX 50 WORDS per message. Be concise.
        2) ADAPT TO USER LEVEL: \(levelNote)
        3) OFF-TOPIC: Reply briefly in Kazakh (max 50 words) and steer back to learning.
        4) EXPLANATION: When the user asks for help understanding Kazakh, give your FULL explanation in \(explainLang). If the user asks their question in Russian, respond entirely in Russian. If they ask in English, respond in English. Keep it concise. Include Kazakh examples. Then add a short Kazakh phrase to practice.

        Conversation:
        \(conv.joined(separator: "\n"))

        Reply as the assistant (in Kazakh, max 50 words, OR in \(explainLang) if explaining a topic):
        """
        return try await generate(prompt: prompt)
    }

    /// Legacy: single-prompt generation via gemini-generator (for scripts, etc.)
    func generate(prompt: String) async throws -> String {
        guard let url = URL(string: geminiGeneratorURL) else {
            throw GeminiServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        request.setValue("Bearer \(SupabaseManager.shared.anonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = ["prompt": prompt]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiServiceError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let message = parseErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
            throw GeminiServiceError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        return try parseResponseText(from: data)
    }

    // MARK: - Response Parsing

    private func parseResponseText(from data: Data) throws -> String {
        // Try common Gemini REST shapes first
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // candidates[0].content.parts[0].text
            if let candidates = json["candidates"] as? [[String: Any]],
               let first = candidates.first,
               let content = first["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String, !text.isEmpty {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Simple { "text": "..." }
            if let text = json["text"] as? String, !text.isEmpty {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Raw JSON -> string fallback for unknown shapes
            if let jsonString = String(data: data, encoding: .utf8), !jsonString.isEmpty {
                return jsonString
            }
        }

        // Plain text response
        if let plain = String(data: data, encoding: .utf8), !plain.isEmpty {
            return plain.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw GeminiServiceError.emptyResponse
    }

    private func parseErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = json["message"] as? String { return message }
            if let error = json["error"] as? String { return error }
            if let msg = json["msg"] as? String { return msg }
        }
        return String(data: data, encoding: .utf8)
    }
}

enum GeminiServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case emptyResponse
    case networkError(String)
    case httpError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .emptyResponse:
            return "Empty response received"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .httpError(let code, let msg):
            return "Error \(code): \(msg)"
        }
    }
}
