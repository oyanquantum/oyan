//
//  ReasonView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI

enum KazakhLearningReason: String, CaseIterable, Identifiable {
    case education
    case travelling
    case workBusiness
    case communication
    case forYourself

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .education: return "book.fill"
        case .travelling: return "airplane"
        case .workBusiness: return "briefcase.fill"
        case .communication: return "message.fill"
        case .forYourself: return "person.fill"
        }
    }

    func title(for language: Language) -> String {
        switch (self, language) {
        case (.education, .english): return "Education"
        case (.education, .russian): return "Образование"

        case (.travelling, .english): return "Travelling"
        case (.travelling, .russian): return "Путешествия"

        case (.workBusiness, .english): return "Work & Business"
        case (.workBusiness, .russian): return "Работа и бизнес"

        case (.communication, .english): return "Communication"
        case (.communication, .russian): return "Общение"

        case (.forYourself, .english): return "For yourself"
        case (.forYourself, .russian): return "Для себя"
        }
    }
}

struct ReasonView: View {
    let selectedLanguage: Language

    @State private var selectedReason: KazakhLearningReason? = nil
    @State private var navigateToNext: Bool = false
    @State private var isLoading: Bool = false

    // Color scheme
    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")

    var speechBubbleText: String {
        selectedLanguage == .english
            ? "Why do you want to learn Kazakh?"
            : "Почему вы хотите учить казахский?"
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
                    ForEach(KazakhLearningReason.allCases) { reason in
                        ReasonOptionButton(
                            title: reason.title(for: selectedLanguage),
                            symbolName: reason.symbolName,
                            isSelected: selectedReason == reason,
                            accentColor: buttonColor
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedReason = reason
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)

                // Continue button
                Button {
                    guard selectedReason != nil else { return }
                    handleContinue()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(selectedLanguage == .english ? "Continue" : "Продолжить")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedReason == nil || isLoading ? buttonColor.opacity(0.45) : buttonColor)
                    )
                    .shadow(color: buttonColor.opacity(selectedReason == nil ? 0.0 : 0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(selectedReason == nil || isLoading)
                .padding(.horizontal, 30)
                .padding(.top, 12)

                Spacer()
            }

            // Eagle in upper right (independent)
            VStack {
                HStack {
                    Spacer()
                    Image("eagle_reason")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 350, maxHeight: 350)
                        .padding(.top, 0)
                        .padding(.trailing, -55)
                }
                Spacer()
            }
            .allowsHitTesting(false)

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
                        .offset(x: -40, y: -2)
                    }
                    .padding(.top, 40)
                    .padding(.trailing, 60)
                }
                Spacer()
            }
            .allowsHitTesting(false)
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToNext) {
            AchievementsView(selectedLanguage: selectedLanguage)
        }
    }
    
    private func handleContinue() {
        guard let reason = selectedReason else { return }
        
        // Get current user ID from UserDefaults
        guard let userIdString = UserDefaults.standard.string(forKey: "currentUserId") ?? UserDefaults.standard.string(forKey: "pendingUserId"),
              let userId = UUID(uuidString: userIdString) else {
            // If no user ID, just navigate (for testing)
            navigateToNext = true
            return
        }
        
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                // Save reason to Supabase
                try await SupabaseService.shared.saveReasonForStudying(
                    userId: userId,
                    reason: reason.rawValue
                )
                
                await MainActor.run {
                    // Store selection for Q5 navigation (Page 4 choice)
                    UserDefaults.standard.set(reason.rawValue, forKey: "selectedReasonForStudying")
                    isLoading = false
                    navigateToNext = true
                }
            } catch {
                await MainActor.run {
                    // Still store selection and navigate even if save fails
                    UserDefaults.standard.set(reason.rawValue, forKey: "selectedReasonForStudying")
                    isLoading = false
                    navigateToNext = true
                }
                print("Error saving reason: \(error)")
            }
        }
    }
}

private struct ReasonOptionButton: View {
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

#Preview {
    NavigationStack {
        ReasonView(selectedLanguage: .english)
    }
}

