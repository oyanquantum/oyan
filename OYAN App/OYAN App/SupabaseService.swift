//
//  SupabaseService.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        self.client = SupabaseManager.shared.client
    }
    
    // Register a new user with username and password
    func registerUser(username: String, password: String) async throws -> UUID {
        do {
            // Check if username already exists
            struct UserCheck: Decodable {
                let id: String
            }
            
            let existingUsers: [UserCheck] = try await client
                .from("users")
                .select("id")
                .eq("username", value: username)
                .execute()
                .value
            
            if !existingUsers.isEmpty {
                throw SupabaseError.usernameAlreadyExists
            }
            
            // Hash password (in production, use proper hashing like bcrypt)
            // For now, we'll store it as-is (NOT RECOMMENDED FOR PRODUCTION)
            let hashedPassword = password // TODO: Implement proper password hashing
            
            // Create new user profile
            let newProfileId = UUID()
            
            // Insert user with username and password
            // Note: This assumes your Supabase table has username and password columns
            // If not, you'll need to add them via Supabase dashboard
            struct UserInsert: Encodable {
                let id: String
                let full_name: String
                let age: Int?
                let knowledge_level: String?
                let num_level: Int?
                let current_unit: Int?
                let level: String?
                let username: String
                let password: String
                let reason_for_studying: String?
                let study_time_minutes: Int?
                let start_option: String?
                let onboarding_completed: Bool?
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case full_name
                    case age
                    case knowledge_level
                    case num_level
                    case current_unit
                    case level
                    case username
                    case password
                    case reason_for_studying
                    case study_time_minutes
                    case start_option
                    case onboarding_completed
                }
            }
            
            let userData = UserInsert(
                id: newProfileId.uuidString,
                full_name: "",
                age: nil,
                knowledge_level: nil,
                num_level: 1,
                current_unit: 1,
                level: nil,
                username: username,
                password: hashedPassword,
                reason_for_studying: nil,
                study_time_minutes: nil,
                start_option: nil,
                onboarding_completed: false
            )
            
            try await client
                .from("users")
                .insert(userData)
                .execute()
            
            return newProfileId
        } catch {
            print("Supabase registerUser error: \(error)")
            let errorString = String(describing: error).lowercased()
            
            // Map duplicate/unique constraint to username taken (so UI can show friendly message)
            if errorString.contains("duplicate") || errorString.contains("unique") || errorString.contains("already exists") {
                throw SupabaseError.usernameAlreadyExists
            }
            // Check for common Supabase errors (rethrow as generic so UI can show friendly message)
            if errorString.contains("column") && errorString.contains("does not exist") {
                throw NSError(domain: "SupabaseError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Something went wrong. Please try again."])
            }
            if errorString.contains("relation") && errorString.contains("does not exist") {
                throw NSError(domain: "SupabaseError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Something went wrong. Please try again."])
            }
            if errorString.contains("permission denied") || errorString.contains("unauthorized") {
                throw NSError(domain: "SupabaseError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Something went wrong. Please try again."])
            }
            if let urlError = error as? URLError {
                throw SupabaseError.networkError
            }
            throw NSError(domain: "SupabaseError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Something went wrong. Please try again."])
        }
    }
    
    // Login with username and password
    func loginUser(username: String, password: String) async throws -> UUID {
        do {
            struct UserLogin: Decodable {
                let id: String
                let password: String
            }
            
            let users: [UserLogin] = try await client
                .from("users")
                .select("id, password")
                .eq("username", value: username)
                .execute()
                .value
            
            guard let user = users.first,
                  let userId = UUID(uuidString: user.id) else {
                throw SupabaseError.userNotFound
            }
            
            // Verify password (in production, use proper password verification)
            guard user.password == password else {
                throw SupabaseError.invalidPassword
            }
            
            return userId
        } catch {
            print("Supabase loginUser error: \(error)")
            let errorString = String(describing: error)
            
            // Check for common Supabase errors
            if errorString.contains("column") && errorString.contains("does not exist") {
                throw NSError(domain: "SupabaseError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database error: Missing columns. Please ensure your 'users' table has 'username' and 'password' columns."])
            }
            if errorString.contains("relation") && errorString.contains("does not exist") {
                throw NSError(domain: "SupabaseError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Database error: 'users' table does not exist. Please create it in Supabase."])
            }
            if errorString.contains("permission denied") || errorString.contains("unauthorized") {
                throw NSError(domain: "SupabaseError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Permission error: Check your Supabase API key permissions."])
            }
            if let urlError = error as? URLError {
                throw NSError(domain: "NetworkError", code: urlError.code.rawValue, userInfo: [NSLocalizedDescriptionKey: "Network error: \(urlError.localizedDescription)"])
            }
            throw NSError(domain: "SupabaseError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Supabase error: \(errorString)"])
        }
    }
    
    // Update user profile (name and age)
    func updateUserProfile(userId: UUID, fullName: String, age: Int?) async throws {
        struct UserUpdate: Encodable {
            let full_name: String
            let age: Int?
        }
        
        let updateData = UserUpdate(
            full_name: fullName,
            age: age
        )
        
        try await client
            .from("users")
            .update(updateData)
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    // Save reason for studying
    func saveReasonForStudying(userId: UUID, reason: String) async throws {
        struct ReasonUpdate: Encodable {
            let reason_for_studying: String
        }
        
        let updateData = ReasonUpdate(reason_for_studying: reason)
        
        try await client
            .from("users")
            .update(updateData)
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    // Save study time
    func saveStudyTime(userId: UUID, minutes: Int) async throws {
        struct StudyTimeUpdate: Encodable {
            let study_time_minutes: Int
        }
        
        let updateData = StudyTimeUpdate(study_time_minutes: minutes)
        
        try await client
            .from("users")
            .update(updateData)
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    // Save placement test result (level tier) so user goes to main page on next login.
    // Uses "level" column. Dictionary form ensures correct key for PostgREST.
    func saveTestResult(userId: UUID, level: String) async throws {
        let payload: [String: String] = ["level": level]
        try await client
            .from("users")
            .update(payload)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // Update current lesson (cloud index 1–11) and current unit (1–3). Unlocks all lessons up to num_level.
    func saveNumLevel(userId: UUID, numLevel: Int) async throws {
        let currentUnit = CourseStructure.node(for: numLevel)?.unitIndex ?? 1
        struct ProgressUpdate: Encodable {
            let num_level: Int
            let current_unit: Int
        }
        try await client
            .from("users")
            .update(ProgressUpdate(num_level: numLevel, current_unit: currentUnit))
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // Update level tier (beginner / intermediate / advanced)
    func saveLevel(userId: UUID, level: String) async throws {
        struct LevelUpdate: Encodable {
            let level: String
        }
        try await client
            .from("users")
            .update(LevelUpdate(level: level))
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // Save start option, mark onboarding as complete, set num_level to 1, current_unit to 1, level to "beginner"
    func completeOnboarding(userId: UUID, startOption: String) async throws {
        struct OnboardingComplete: Encodable {
            let start_option: String
            let onboarding_completed: Bool
            let num_level: Int
            let current_unit: Int
            let level: String
        }
        
        let updateData = OnboardingComplete(
            start_option: startOption,
            onboarding_completed: true,
            num_level: 1,
            current_unit: 1,
            level: "beginner"
        )
        
        try await client
            .from("users")
            .update(updateData)
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    // Get user profile
    func getUserProfile(userId: UUID) async throws -> UserProfile {
        let profiles: [UserProfile] = try await client
            .from("users")
            .select("*")
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        
        guard let profile = profiles.first else {
            throw SupabaseError.userNotFound
        }
        
        return profile
    }

    // MARK: - Chat messages

    struct ChatMessageRow: Decodable {
        let id: String
        let user_id: String
        let role: String
        let text: String
        let created_at: String
    }

    /// Fetch all chat messages for the user, ordered by created_at.
    func fetchChatMessages(userId: UUID) async throws -> [ChatMessage] {
        let rows: [ChatMessageRow] = try await client
            .from("chat_messages")
            .select("id, user_id, role, text, created_at")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return rows.compactMap { row -> ChatMessage? in
            guard let uuid = UUID(uuidString: row.id),
                  let role = ChatMessage.Role(rawValue: row.role) else { return nil }
            let date = formatter.date(from: row.created_at)
                ?? fallback.date(from: row.created_at)
                ?? Date()
            return ChatMessage(id: uuid, role: role, text: row.text, timestamp: date)
        }
    }

    /// Save a chat message to the database.
    func saveChatMessage(userId: UUID, role: ChatMessage.Role, text: String) async throws {
        struct Insert: Encodable {
            let user_id: String
            let role: String
            let text: String
        }
        try await client
            .from("chat_messages")
            .insert(Insert(
                user_id: userId.uuidString,
                role: role.rawValue,
                text: text
            ))
            .execute()
    }

    // MARK: - Vocabulary

    struct VocabularyEntryRow: Decodable {
        let id: String
        let user_id: String
        let word: String
        let translation_en: String
        let translation_ru: String
        let lesson_index: Int
    }

    /// Fetch all vocabulary entries for the user, ordered by lesson_index then word.
    func fetchVocabulary(userId: UUID) async throws -> [VocabularyEntry] {
        let rows: [VocabularyEntryRow] = try await client
            .from("vocabulary_entries")
            .select("id, user_id, word, translation_en, translation_ru, lesson_index")
            .eq("user_id", value: userId.uuidString)
            .order("lesson_index", ascending: true)
            .order("word", ascending: true)
            .execute()
            .value

        return rows.compactMap { row -> VocabularyEntry? in
            guard let uuid = UUID(uuidString: row.id) else { return nil }
            return VocabularyEntry(
                id: uuid,
                word: row.word,
                translationEn: row.translation_en,
                translationRu: row.translation_ru,
                lessonIndex: row.lesson_index
            )
        }
    }

    /// Insert vocabulary entries. Ignores duplicates (same user_id, word).
    func addVocabularyEntries(userId: UUID, entries: [VocabularyEntry]) async throws {
        guard !entries.isEmpty else { return }
        struct InsertRow: Encodable {
            let user_id: String
            let word: String
            let translation_en: String
            let translation_ru: String
            let lesson_index: Int
        }
        let rows = entries.map { e in
            InsertRow(
                user_id: userId.uuidString,
                word: e.word,
                translation_en: e.translationEn,
                translation_ru: e.translationRu,
                lesson_index: e.lessonIndex
            )
        }
        try await client
            .from("vocabulary_entries")
            .upsert(rows, onConflict: "user_id,word", ignoreDuplicates: true)
            .execute()
    }

    // MARK: - Course content (Edge Function: Gemini + KazLLM)

    /// Calls the Supabase Edge Function to generate lesson content.
    /// Uses Gemini (prior-context aware) and KazLLM (grammar correction).
    /// - Parameters:
    ///   - unitSummary: Summary of the current lesson/unit
    ///   - priorLessonsSummary: Summary of lessons the user has already completed (for personalization)
    ///   - cloudIndex: Cloud index 1–11 (for logging/debugging)
    func generateCourseContent(
        for unitSummary: String,
        priorLessonsSummary: String? = nil,
        cloudIndex: Int? = nil
    ) async throws -> GeneratedLessonContent {
        let url = SupabaseManager.shared.supabaseURL
            .appendingPathComponent("functions/v1/generate-course-content")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseManager.shared.anonKey)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = ["unit_summary": unitSummary]
        if let prior = priorLessonsSummary, !prior.isEmpty { body["prior_lessons_summary"] = prior }
        if let idx = cloudIndex { body["cloud_index"] = idx }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        guard http.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SupabaseService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Edge function error: \(message)"])
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GeneratedLessonContent.self, from: data)
    }
}

enum SupabaseError: LocalizedError {
    case usernameAlreadyExists
    case userNotFound
    case invalidPassword
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .usernameAlreadyExists:
            return "Username already exists"
        case .userNotFound:
            return "User not found"
        case .invalidPassword:
            return "Invalid password"
        case .networkError:
            return "Network error occurred"
        }
    }
}
