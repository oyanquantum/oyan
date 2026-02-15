//
//  WelcomeView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI

enum Language: String, CaseIterable {
    case english = "English"
    case russian = "Russian"
    
    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .russian: return "🇷🇺"
        }
    }
}

struct WelcomeView: View {
    @State private var selectedLanguage: Language = .english
    @State private var showLanguageMenu = false
    @State private var navigateToNext = false
    
    // Color scheme
    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")
    
    var greeting: String {
        switch selectedLanguage {
        case .english: return "Welcome!"
        case .russian: return "Добро пожаловать!"
        }
    }
    
    var learnText: String {
        switch selectedLanguage {
        case .english: return "Learn Kazakh with OYAN"
        case .russian: return "Изучайте казахский с OYAN"
        }
    }
    
    var startButtonText: String {
        switch selectedLanguage {
        case .english: return "Start"
        case .russian: return "Начать"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                // Your background: add welcome_background.png in Assets → welcome_background
                Image("welcome_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top bar with greeting and language selector
                    ZStack(alignment: .topTrailing) {
                        HStack {
                            Text(greeting)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.top, 48)
                        
                        // Language selector (moved down slightly)
                        VStack(alignment: .trailing, spacing: 8) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showLanguageMenu.toggle()
                                }
                            }) {
                                Text(selectedLanguage.flag)
                                    .font(.system(size: 40))
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.3))
                                    )
                            }
                            .padding(.top, 22)
                            
                            if showLanguageMenu {
                                ForEach(Language.allCases, id: \.self) { language in
                                    if language != selectedLanguage {
                                        Button(action: {
                                            selectedLanguage = language
                                            UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                showLanguageMenu = false
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Text(language.rawValue)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                Text(language.flag)
                                                    .font(.title3)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white)
                                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            )
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    Spacer()
                    
                    // Eagle image in the middle
                    Image("eagle")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 750, maxHeight: 750)
                        .padding(.bottom, -20)
                    
                    // Learn Kazakh text + Start button (moved up together)
                    VStack(spacing: 0) {
                        Text(learnText)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.top, 0)
                            .padding(.bottom, 12)
                        
                        Button(action: {
                            navigateToNext = true
                        }) {
                            Text(startButtonText)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: 200)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(buttonColor)
                                )
                                .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.bottom, 28)
                    }
                    .offset(y: -72)
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $navigateToNext) {
                RegistrationView(selectedLanguage: selectedLanguage)
                    .onAppear { UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selectedLanguage") }
            }
            .onTapGesture {
                if showLanguageMenu {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showLanguageMenu = false
                    }
                }
            }
        }
    }
}


// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    WelcomeView()
}
