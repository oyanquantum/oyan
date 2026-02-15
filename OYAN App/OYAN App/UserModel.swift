//
//  UserModel.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import Foundation
import Combine

struct User: Codable, Identifiable {
    let id: UUID
    var username: String
    var password: String
    var languageLevel: String
    var age: Int
    var reasonForStudying: String
    
    init(id: UUID = UUID(), username: String, password: String, languageLevel: String, age: Int, reasonForStudying: String) {
        self.id = id
        self.username = username
        self.password = password
        self.languageLevel = languageLevel
        self.age = age
        self.reasonForStudying = reasonForStudying
    }
}

class UserDatabase: ObservableObject {
    static let shared = UserDatabase()
    private let usersKey = "storedUsers"
    
    @Published var users: [User] = []
    
    private init() {
        loadUsers()
    }
    
    func loadUsers() {
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let decoded = try? JSONDecoder().decode([User].self, from: data) {
            users = decoded
        }
    }
    
    func saveUsers() {
        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: usersKey)
        }
    }
    
    func addUser(_ user: User) -> Bool {
        // Check if username already exists
        if users.contains(where: { $0.username.lowercased() == user.username.lowercased() }) {
            return false
        }
        users.append(user)
        saveUsers()
        return true
    }
    
    func getUser(username: String) -> User? {
        return users.first { $0.username.lowercased() == username.lowercased() }
    }
    
    func validateLogin(username: String, password: String) -> Bool {
        guard let user = getUser(username: username) else { return false }
        return user.password == password
    }
}
