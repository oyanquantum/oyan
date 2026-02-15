//
//  TimeSelectionView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI

struct TimeSelectionView: View {
    let selectedLanguage: Language
    
    @State private var selectedMinutes: Int? = nil
    @State private var navigateToNext: Bool = false
    @State private var isLoading: Bool = false
    
    // Color scheme
    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")
    
    let timeOptions = [5, 10, 15, 20]
    
    var speechBubbleText: String {
        selectedLanguage == .english
            ? "How much time do you want to spend learning with me?"
            : "Сколько времени вы хотите проводить со мной за обучением?"
    }
    
    var continueButtonText: String {
        selectedLanguage == .english ? "Continue" : "Продолжить"
    }
    
    var minutesText: String {
        selectedLanguage == .english ? "minutes" : "минут"
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            // Time options (static layout)
            VStack(spacing: 14) {
                Spacer()
                    .frame(height: 220)
                
                // Time selection boxes
                HStack(spacing: 12) {
                    ForEach(timeOptions, id: \.self) { minutes in
                        TimeOptionBox(
                            minutes: minutes,
                            minutesText: minutesText,
                            isSelected: selectedMinutes == minutes,
                            accentColor: buttonColor
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedMinutes = minutes
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                // Continue button
                Button {
                    if let minutes = selectedMinutes {
                        handleContinue(minutes: minutes)
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
                            .fill(selectedMinutes == nil || isLoading ? buttonColor.opacity(0.45) : buttonColor)
                    )
                    .shadow(color: buttonColor.opacity(selectedMinutes == nil ? 0.0 : 0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(selectedMinutes == nil || isLoading)
                .padding(.horizontal, 30)
                .padding(.top, 12)

                Spacer()
            }
            
            // Eagle in upper right (same as page 3)
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
                        .offset(x: -30, y: -2)
                    }
                    .padding(.trailing, 60)
                    .padding(.top, 40)
                }
                Spacer()
            }
            .allowsHitTesting(false)
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToNext) {
            StartOptionView(selectedLanguage: selectedLanguage)
        }
    }
    
    private func handleContinue(minutes: Int) {
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
                // Save study time to Supabase
                try await SupabaseService.shared.saveStudyTime(
                    userId: userId,
                    minutes: minutes
                )
                
                await MainActor.run {
                    UserDefaults.standard.set(minutes, forKey: "dailyStudyMinutesGoal")
                    isLoading = false
                    navigateToNext = true
                }
            } catch {
                await MainActor.run {
                    UserDefaults.standard.set(minutes, forKey: "dailyStudyMinutesGoal")
                    isLoading = false
                    navigateToNext = true
                }
                print("Error saving study time: \(error)")
            }
        }
    }
}

private struct TimeOptionBox: View {
    let minutes: Int
    let minutesText: String
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : accentColor)
                
                Text(minutesText)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
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

private struct NextPagePlaceholderView: View {
    let selectedLanguage: Language
    let selectedMinutes: Int?
    
    var body: some View {
        ZStack {
            Color(hex: "#fbf5e0").ignoresSafeArea()
            VStack(spacing: 12) {
                Text(selectedLanguage == .english ? "Next page" : "Следующая страница")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(
                    (selectedLanguage == .english ? "Selected: " : "Вы выбрали: ")
                    + "\(selectedMinutes ?? 0) " + (selectedLanguage == .english ? "minutes" : "минут")
                )
                .font(.title3)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    NavigationStack {
        TimeSelectionView(selectedLanguage: .english)
    }
}
