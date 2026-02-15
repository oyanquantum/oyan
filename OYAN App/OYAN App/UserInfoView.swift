//
//  UserInfoView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI

struct UserInfoView: View {
    let selectedLanguage: Language
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var navigateToNext: Bool = false
    @State private var isLoading: Bool = false
    
    // Color scheme
    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")
    
    var speechBubbleText: String {
        selectedLanguage == .english ? "Let's get to know each other!" : "Давайте познакомимся!"
    }
    
    var namePlaceholder: String {
        selectedLanguage == .english ? "Name" : "Имя"
    }
    
    var agePlaceholder: String {
        selectedLanguage == .english ? "Age" : "Возраст"
    }
    
    var continueButtonText: String {
        selectedLanguage == .english ? "Continue" : "Продолжить"
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text(namePlaceholder)
                        .font(.headline)
                    TextField(namePlaceholder, text: $name)
                        .textFieldStyle(CustomTextFieldStyle())
                        .onChange(of: name) { oldValue, newValue in
                            // Filter out numbers and keep only letters and spaces
                            name = newValue.filter { $0.isLetter || $0.isWhitespace || $0 == "-" || $0 == "'" }
                        }
                }
                
                // Age field
                VStack(alignment: .leading, spacing: 8) {
                    Text(agePlaceholder)
                        .font(.headline)
                    TextField(agePlaceholder, text: $age)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CustomTextFieldStyle())
                        .onChange(of: age) { oldValue, newValue in
                            // Filter out non-numeric characters
                            age = newValue.filter { $0.isNumber }
                        }
                }
                
                // Error message
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal)
                }
                
                // Continue button
                Button(action: handleContinue) {
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
                            .fill(isLoading ? buttonColor.opacity(0.6) : buttonColor)
                    )
                    .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isLoading)
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity)
            
            // Eagle with speech bubble in upper right corner
            VStack {
                HStack {
                    Spacer()
                    ZStack(alignment: .topTrailing) {
                        // Speech bubble
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
                            
                            // Speech bubble tail
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
                        .padding(.trailing, 20)
                        .padding(.top, 50)
                        
                        // Eagle image
                        Image("eagle_speech")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 250, maxHeight: 250)
                            .padding(.trailing, -20) // moved further to the right
                            .padding(.top, 60)
                    }
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToNext) {
            ReasonView(selectedLanguage: selectedLanguage)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private func handleContinue() {
        showError = false
        errorMessage = ""
        
        guard !name.isEmpty else {
            showError(message: selectedLanguage == .english ? "Please enter your name" : "Введите ваше имя")
            return
        }
        
        guard !age.isEmpty, let ageInt = Int(age), ageInt > 0 else {
            showError(message: selectedLanguage == .english ? "Please enter a valid age" : "Введите корректный возраст")
            return
        }
        
        // Get current user ID from UserDefaults
        guard let userIdString = UserDefaults.standard.string(forKey: "currentUserId") ?? UserDefaults.standard.string(forKey: "pendingUserId"),
              let userId = UUID(uuidString: userIdString) else {
            showError(message: selectedLanguage == .english ? "User session not found. Please log in again." : "Сессия пользователя не найдена. Пожалуйста, войдите снова.")
            return
        }
        
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                // Save name and age to Supabase
                try await SupabaseService.shared.updateUserProfile(
                    userId: userId,
                    fullName: name,
                    age: ageInt
                )
                
                await MainActor.run {
                    isLoading = false
                    navigateToNext = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let errorMsg = selectedLanguage == .english 
                        ? "Failed to save profile. Please try again." 
                        : "Не удалось сохранить профиль. Попробуйте еще раз."
                    showError(message: errorMsg)
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// Custom text field style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        UserInfoView(selectedLanguage: .english)
    }
}
