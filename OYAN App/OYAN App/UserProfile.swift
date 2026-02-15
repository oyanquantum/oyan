//
//  UserProfile.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var username: String?
    var fullName: String
    var age: Int?
    var knowledgeLevel: String?
    /// Numeric level = current lesson (cloud index 1–11). User on lesson 2 has numLevel 2; not started = 1.
    var numLevel: Int?
    /// Unit the user is currently on (1–3). Derived from the lesson at num_level.
    var currentUnit: Int?
    /// Tier: "beginner", "intermediate", or "advanced".
    var level: String?
    var reasonForStudying: String?
    var studyTimeMinutes: Int?
    var startOption: String?
    var onboardingCompleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case age
        case knowledgeLevel = "knowledge_level"
        case numLevel = "num_level"
        case currentUnit = "current_unit"
        case level
        case reasonForStudying = "reason_for_studying"
        case studyTimeMinutes = "study_time_minutes"
        case startOption = "start_option"
        case onboardingCompleted = "onboarding_completed"
    }
}

