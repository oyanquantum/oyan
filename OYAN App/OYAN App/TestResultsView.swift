//
//  TestResultsView.swift
//  OYAN App
//
//  Shows Kazakh level after the test: G (0–5 general), S (0–3 specialized).
//  Final Score = (G/5)×0.7 + (S/3)×0.3 → Beginner / Intermediate / Advanced.
//

import SwiftUI

private let testGeneralKey = "testGeneralCorrect"
private let testSpecializedKey = "testSpecializedCorrect"

enum KazakhLevel: String {
    case beginner
    case intermediate
    case advanced

    func displayName(english: Bool) -> String {
        switch self {
        case .beginner: return english ? "Beginner" : "Начинающий"
        case .intermediate: return english ? "Intermediate" : "Средний"
        case .advanced: return english ? "Advanced" : "Продвинутый"
        }
    }
}

struct TestResultsView: View {
    let selectedLanguage: Language

    @State private var navigateToHome: Bool = false
    @State private var isSaving: Bool = false
    @State private var saveError: String? = nil
    @State private var showSaveError: Bool = false

    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")

    private var g: Int {
        UserDefaults.standard.integer(forKey: testGeneralKey)
    }

    private var s: Int {
        UserDefaults.standard.integer(forKey: testSpecializedKey)
    }

    private var finalScore: Double {
        let gNorm = min(5, max(0, g))
        let sNorm = min(3, max(0, s))
        return (Double(gNorm) / 5.0) * 0.7 + (Double(sNorm) / 3.0) * 0.3
    }

    private var level: KazakhLevel {
        if finalScore >= 0.70 { return .advanced }
        if finalScore >= 0.40 { return .intermediate }
        return .beginner
    }

    var bubbleText: String {
        let levelName = level.displayName(english: selectedLanguage == .english)
        return selectedLanguage == .english
            ? "Great job. Your level is \(levelName)."
            : "Отлично. Ваш уровень — \(levelName)."
    }

    var courseInDevelopmentText: String {
        selectedLanguage == .english
            ? "Course for you is currently in development:)"
            : "Курс для вас сейчас в разработке:)"
    }

    var continueButtonText: String {
        selectedLanguage == .english ? "Continue" : "Продолжить"
    }

    /// Beginner sees level result; intermediate/advanced see "course in development" message.
    private var isCourseAvailable: Bool { level == .beginner }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)
            ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                if isCourseAvailable {
                    // Beginner: show level result with eagle
                    ZStack(alignment: .topTrailing) {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(bubbleText)
                                .font(.headline)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addLine(to: CGPoint(x: 20, y: 0))
                                path.addLine(to: CGPoint(x: 10, y: 15))
                                path.closeSubpath()
                            }
                            .fill(Color.white)
                            .frame(width: 20, height: 15)
                            .offset(x: -50, y: -2)
                        }
                        .padding(.bottom, 20)

                        Image("eagle_happy")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 320, maxHeight: 320)
                    }
                } else {
                    // Intermediate / Advanced: course in development message
                    VStack(spacing: 20) {
                        Text(courseInDevelopmentText)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity)
                }

                Spacer()

                Button {
                    saveResultAndGoHome()
                } label: {
                    Group {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(continueButtonText)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(buttonColor))
                    .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
            Spacer()
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToHome) {
            HomeView(selectedLanguage: selectedLanguage)
        }
        .alert(selectedLanguage == .english ? "Could not save to server" : "Не удалось сохранить на сервер", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { showSaveError = false }
        } message: {
            Text([saveError ?? "", selectedLanguage == .english
                 ? "Run supabase_users_rls.sql in Supabase → SQL Editor to fix."
                 : "Выполните supabase_users_rls.sql в Supabase → SQL Editor."].joined(separator: "\n\n"))
        }
    }

    private func saveResultAndGoHome() {
        let userIdString = UserDefaults.standard.string(forKey: "currentUserId") ?? UserDefaults.standard.string(forKey: "pendingUserId")
        guard let idString = userIdString, let userId = UUID(uuidString: idString) else {
            navigateToHome = true
            return
        }
        Task {
            await MainActor.run { isSaving = true; saveError = nil }
            var lastError: Error?
            for attempt in 1...2 {
                do {
                    try await SupabaseService.shared.saveTestResult(userId: userId, level: level.rawValue)
                    lastError = nil
                    break
                } catch {
                    lastError = error
                    print("Save test result attempt \(attempt) failed: \(error)")
                }
            }
            // Always save locally so progress persists and login can use it if Supabase failed
            UserDefaults.standard.set(true, forKey: "userHasCompletedPlacementTest")
            UserDefaults.standard.set(idString, forKey: "completedTestUserId")
            UserDefaults.standard.set(level.rawValue, forKey: "savedKnowledgeLevel")
            await MainActor.run {
                isSaving = false
                if let err = lastError {
                    saveError = err.localizedDescription
                    showSaveError = true
                }
                // Sign-up flow: promote pendingUserId so ContentView switches to LoggedInRootView (Home)
                if let pending = UserDefaults.standard.string(forKey: "pendingUserId") {
                    UserDefaults.standard.set(pending, forKey: "currentUserId")
                    UserDefaults.standard.removeObject(forKey: "pendingUserId")
                }
                navigateToHome = true
            }
        }
    }
}

// MARK: - Score recording helpers (call from question views)

func recordGeneralCorrect() {
    let current = UserDefaults.standard.integer(forKey: testGeneralKey)
    UserDefaults.standard.set(current + 1, forKey: testGeneralKey)
}

func recordSpecializedCorrect() {
    let current = UserDefaults.standard.integer(forKey: testSpecializedKey)
    UserDefaults.standard.set(current + 1, forKey: testSpecializedKey)
}

func resetTestScores() {
    UserDefaults.standard.set(0, forKey: testGeneralKey)
    UserDefaults.standard.set(0, forKey: testSpecializedKey)
}

#Preview {
    NavigationStack {
        TestResultsView(selectedLanguage: .english)
    }
}
