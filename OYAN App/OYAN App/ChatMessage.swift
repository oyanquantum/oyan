//
//  ChatMessage.swift
//  OYAN App
//
//  Model for chat messages (user + assistant).
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: Role
    let text: String
    let timestamp: Date

    enum Role: String, Codable {
        case user
        case assistant
    }

    init(id: UUID = UUID(), role: Role, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}
