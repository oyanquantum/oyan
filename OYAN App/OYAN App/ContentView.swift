//
//  ContentView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI

private let selectedLanguageKey = "selectedLanguage"

struct ContentView: View {
    @AppStorage("currentUserId") private var currentUserId: String = ""

    private var selectedLanguage: Language {
        let raw = UserDefaults.standard.string(forKey: selectedLanguageKey) ?? Language.english.rawValue
        return Language(rawValue: raw) ?? .english
    }

    var body: some View {
        Group {
            if currentUserId.isEmpty {
                WelcomeView()
            } else {
                LoggedInRootView(selectedLanguage: selectedLanguage)
            }
        }
    }
}

#Preview {
    ContentView()
}
