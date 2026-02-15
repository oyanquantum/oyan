//
//  LoggedInRootView.swift
//  OYAN App
//
//  After login: fetches profile and shows UserInfoView (onboarding), HomeView, or LanguageTestView.
//

import SwiftUI

struct LoggedInRootView: View {
    let selectedLanguage: Language

    @State private var profile: UserProfile?
    @State private var isLoading = true
    @State private var showProfile = false
    @State private var showHome = false
    @State private var showTest = false

    private var userId: UUID? {
        guard let s = UserDefaults.standard.string(forKey: "currentUserId") else { return nil }
        return UUID(uuidString: s)
    }

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    Color(hex: "#fbf5e0").ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.2)
                }
            } else if showProfile {
                UserInfoView(selectedLanguage: selectedLanguage)
            } else if showTest {
                LanguageTestView(selectedLanguage: selectedLanguage)
            } else {
                NavigationStack {
                    HomeView(selectedLanguage: selectedLanguage)
                }
            }
        }
        .task { await resolveDestination() }
    }

    private func resolveDestination() async {
        guard let userId = userId else {
            await MainActor.run { isLoading = false; showHome = true }
            return
        }
        do {
            let p = try await SupabaseService.shared.getUserProfile(userId: userId)
            await MainActor.run {
                profile = p
                if let reason = p.reasonForStudying {
                    UserDefaults.standard.set(reason, forKey: "selectedReasonForStudying")
                }
                let serverLevel = p.level ?? p.knowledgeLevel
                let hasLevelOnServer = serverLevel != nil && !serverLevel!.isEmpty
                if hasLevelOnServer, let level = serverLevel {
                    UserDefaults.standard.set(level, forKey: "savedKnowledgeLevel")
                    UserDefaults.standard.set(true, forKey: "userHasCompletedPlacementTest")
                    UserDefaults.standard.set(userId.uuidString, forKey: "completedTestUserId")
                }
                isLoading = false
                if hasLevelOnServer {
                    showHome = true
                    return
                }
                if p.onboardingCompleted == true {
                    let completedTest = UserDefaults.standard.bool(forKey: "userHasCompletedPlacementTest")
                        && UserDefaults.standard.string(forKey: "completedTestUserId") == userId.uuidString
                    if completedTest {
                        showHome = true
                    } else if let startOption = p.startOption {
                        if startOption == "startFromBeginning" {
                            showHome = true
                        } else if startOption == "findOutLevel" {
                            showTest = true
                        } else {
                            showProfile = true
                        }
                    } else {
                        showProfile = true
                    }
                } else {
                    showProfile = true
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                showHome = true
            }
        }
    }
}
