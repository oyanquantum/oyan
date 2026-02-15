//
//  StartOptionView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI

enum StartOption: String, CaseIterable, Identifiable {
    case startFromBeginning
    case findOutLevel
    
    var id: String { rawValue }
    
    var symbolName: String {
        switch self {
        case .startFromBeginning: return "play.circle.fill"
        case .findOutLevel: return "magnifyingglass.circle.fill"
        }
    }
    
    func title(for language: Language) -> String {
        switch (self, language) {
        case (.startFromBeginning, .english): return "Start from the beginning"
        case (.startFromBeginning, .russian): return "Начать с начала"
            
        case (.findOutLevel, .english): return "Find out your level"
        case (.findOutLevel, .russian): return "Узнать свой уровень"
        }
    }
}

struct StartOptionView: View {
    let selectedLanguage: Language
    
    @State private var selectedOption: StartOption? = nil
    @State private var navigateToMain: Bool = false
    @State private var navigateToTest: Bool = false
    @State private var isLoading: Bool = false
    
    // Color scheme
    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")
    
    var speechBubbleText: String {
        selectedLanguage == .english
            ? "How would you like to start?"
            : "Как вы хотите начать?"
    }
    
    var continueButtonText: String {
        selectedLanguage == .english ? "Continue" : "Продолжить"
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            // Options (static layout)
            VStack(spacing: 14) {
                Spacer()
                    .frame(height: 220)
                
                VStack(spacing: 12) {
                    ForEach(StartOption.allCases) { option in
                        StartOptionButton(
                            title: option.title(for: selectedLanguage),
                            symbolName: option.symbolName,
                            isSelected: selectedOption == option,
                            accentColor: buttonColor
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedOption = option
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                // Continue button
                Button {
                    if let option = selectedOption {
                        handleContinue(option: option)
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(continueButtonText)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedOption == nil || isLoading ? buttonColor.opacity(0.45) : buttonColor)
                    )
                    .shadow(color: buttonColor.opacity(selectedOption == nil ? 0.0 : 0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(selectedOption == nil || isLoading)
                .padding(.horizontal, 30)
                .padding(.top, 12)

                Spacer()
            }
            
            // Eagle in upper right (same as page 2)
            VStack {
                HStack {
                    Spacer()
                    Image("eagle_speech")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 250, maxHeight: 250)
                        .padding(.trailing, -20)
                        .padding(.top, 60)
                }
                Spacer()
            }
            
            // Bubble in upper right (independent from eagle)
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(speechBubbleText)
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        
                        // Speech bubble tail (points roughly toward eagle)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 20, y: 0))
                            path.addLine(to: CGPoint(x: 10, y: 15))
                            path.closeSubpath()
                        }
                        .fill(Color.white)
                        .frame(width: 20, height: 15)
                        .offset(x: -30, y: -2)
                    }
                    .padding(.trailing, 60)
                    .padding(.top, 40)
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToMain) {
            HomeView(selectedLanguage: selectedLanguage)
        }
        .navigationDestination(isPresented: $navigateToTest) {
            LanguageTestView(selectedLanguage: selectedLanguage)
        }
    }
    
    private func handleContinue(option: StartOption) {
        // Get current user ID from UserDefaults
        guard let userIdString = UserDefaults.standard.string(forKey: "currentUserId") ?? UserDefaults.standard.string(forKey: "pendingUserId"),
              let userId = UUID(uuidString: userIdString) else {
            // If no user ID, just navigate (for testing)
            if option == .startFromBeginning {
                navigateToMain = true
            } else {
                navigateToTest = true
            }
            return
        }
        
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                if option == .startFromBeginning {
                    // Set level to "beginner" in DB first (same API as test result — uses "level" column only)
                    try await SupabaseService.shared.saveTestResult(userId: userId, level: "beginner")
                }
                // Then save start option and mark onboarding as complete (may fail if other columns missing)
                try? await SupabaseService.shared.completeOnboarding(
                    userId: userId,
                    startOption: option.rawValue
                )
                await MainActor.run {
                    isLoading = false
                    if option == .startFromBeginning {
                        UserDefaults.standard.set("beginner", forKey: "savedKnowledgeLevel")
                        UserDefaults.standard.set(true, forKey: "userHasCompletedPlacementTest")
                        UserDefaults.standard.set(userIdString, forKey: "completedTestUserId")
                        // Sign-up flow: promote pendingUserId so ContentView switches to LoggedInRootView (Home)
                        if UserDefaults.standard.string(forKey: "pendingUserId") != nil {
                            UserDefaults.standard.set(userIdString, forKey: "currentUserId")
                            UserDefaults.standard.removeObject(forKey: "pendingUserId")
                        } else {
                            navigateToMain = true
                        }
                    } else {
                        navigateToTest = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if option == .startFromBeginning {
                        UserDefaults.standard.set("beginner", forKey: "savedKnowledgeLevel")
                        UserDefaults.standard.set(true, forKey: "userHasCompletedPlacementTest")
                        UserDefaults.standard.set(userIdString, forKey: "completedTestUserId")
                        if UserDefaults.standard.string(forKey: "pendingUserId") != nil {
                            UserDefaults.standard.set(userIdString, forKey: "currentUserId")
                            UserDefaults.standard.removeObject(forKey: "pendingUserId")
                        } else {
                            navigateToMain = true
                        }
                    } else {
                        navigateToTest = true
                    }
                }
                print("Error (save level or onboarding): \(error)")
            }
        }
    }
}

private struct StartOptionButton: View {
    let title: String
    let symbolName: String
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundColor(isSelected ? .white : accentColor)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? accentColor : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor.opacity(isSelected ? 0 : 0.35), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct MainPagePlaceholderView: View {
    let selectedLanguage: Language
    
    var body: some View {
        ZStack {
            Color(hex: "#fbf5e0").ignoresSafeArea()
            VStack(spacing: 12) {
                Text(selectedLanguage == .english ? "Main Page" : "Главная страница")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(selectedLanguage == .english ? "To be designed" : "Будет разработано")
                    .font(.title3)
            }
            .padding(.horizontal, 24)
        }
    }
}


#Preview {
    NavigationStack {
        StartOptionView(selectedLanguage: .english)
    }
}
