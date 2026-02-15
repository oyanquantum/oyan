//
//  RegistrationView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI

enum AuthMode {
    case signUp
    case logIn
}

struct RegistrationView: View {
    let selectedLanguage: Language
    
    @StateObject private var userDatabase = UserDatabase.shared
    @State private var authMode: AuthMode = .logIn
    
    // Form fields
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Error messages
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    // Loading state
    @State private var isLoading: Bool = false
    
    // Navigation
    @State private var navigateToProfile: Bool = false
    @State private var navigateToMain: Bool = false
    @State private var navigateToTest: Bool = false
    
    // Color scheme
    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")
    
    var titleText: String {
        switch authMode {
        case .signUp:
            return selectedLanguage == .english ? "Sign Up" : "Регистрация"
        case .logIn:
            return selectedLanguage == .english ? "Log In" : "Вход"
        }
    }
    
    var switchModeText: String {
        switch authMode {
        case .signUp:
            return selectedLanguage == .english ? "Already have an account? Log In" : "Уже есть аккаунт? Войти"
        case .logIn:
            return selectedLanguage == .english ? "Don't have an account? Sign Up" : "Нет аккаунта? Зарегистрироваться"
        }
    }
    
    var usernamePlaceholder: String {
        selectedLanguage == .english ? "Username" : "Имя пользователя"
    }
    
    var passwordPlaceholder: String {
        selectedLanguage == .english ? "Password" : "Пароль"
    }
    
    var confirmPasswordPlaceholder: String {
        selectedLanguage == .english ? "Confirm Password" : "Подтвердите пароль"
    }
    
    var continueWithGoogleText: String {
        selectedLanguage == .english ? "Continue with Google" : "Продолжить с Google"
    }
    
    var submitButtonText: String {
        switch authMode {
        case .signUp:
            return selectedLanguage == .english ? "Sign Up" : "Зарегистрироваться"
        case .logIn:
            return selectedLanguage == .english ? "Log In" : "Войти"
        }
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Title
                Text(titleText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Mode switcher
                Button(action: {
                    withAnimation {
                        authMode = authMode == .signUp ? .logIn : .signUp
                        clearForm()
                    }
                }) {
                    Text(switchModeText)
                        .font(.subheadline)
                        .foregroundColor(buttonColor)
                        .underline()
                }
                
                // Username field
                VStack(alignment: .leading, spacing: 8) {
                    Text(usernamePlaceholder)
                        .font(.headline)
                    TextField(usernamePlaceholder, text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                .padding(.horizontal, 30)
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text(passwordPlaceholder)
                        .font(.headline)
                    SecureField(passwordPlaceholder, text: $password)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                .padding(.horizontal, 30)
                
                // Confirm password (only for sign up)
                if authMode == .signUp {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(confirmPasswordPlaceholder)
                            .font(.headline)
                        SecureField(confirmPasswordPlaceholder, text: $confirmPassword)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 30)
                }
                
                // Error message
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal, 30)
                }
                
                // Submit button
                Button(action: handleSubmit) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(submitButtonText)
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
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToProfile) {
            UserInfoView(selectedLanguage: selectedLanguage)
        }
        .navigationDestination(isPresented: $navigateToMain) {
            HomeView(selectedLanguage: selectedLanguage)
        }
        .navigationDestination(isPresented: $navigateToTest) {
            LanguageTestView(selectedLanguage: selectedLanguage)
        }
    }
    
    private func clearForm() {
        username = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
        showError = false
    }
    
    private func handleSubmit() {
        showError = false
        errorMessage = ""
        
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                let userId: UUID
                
                switch authMode {
                case .signUp:
                    userId = try await handleSignUp()
                    // Use pendingUserId so ContentView stays on WelcomeView and we can navigate to onboarding
                    UserDefaults.standard.set(userId.uuidString, forKey: "pendingUserId")
                    await MainActor.run {
                        isLoading = false
                        navigateToProfile = true
                    }
                case .logIn:
                    userId = try await handleLogIn()
                    
                    // Check if user has completed onboarding
                    let profile = try await SupabaseService.shared.getUserProfile(userId: userId)
                    
                    // Save user ID first so it's available everywhere
                    UserDefaults.standard.set(userId.uuidString, forKey: "currentUserId")
                    
                    await MainActor.run {
                        // Store Page 4 selection for Q5 navigation (returning users)
                        if let reason = profile.reasonForStudying {
                            UserDefaults.standard.set(reason, forKey: "selectedReasonForStudying")
                        }
                        // Restore level from server so main page shows correct level (beginner/intermediate/advanced)
                        let serverLevel = profile.level ?? profile.knowledgeLevel
                        let hasLevelOnServer = (serverLevel != nil && !serverLevel!.isEmpty)
                        if hasLevelOnServer, let level = serverLevel {
                            UserDefaults.standard.set(level, forKey: "savedKnowledgeLevel")
                            UserDefaults.standard.set(true, forKey: "userHasCompletedPlacementTest")
                            UserDefaults.standard.set(userId.uuidString, forKey: "completedTestUserId")
                        }
                        isLoading = false
                        
                        // If user has a level on server (completed test), always go to main — don't redo test/onboarding
                        if hasLevelOnServer {
                            navigateToMain = true
                            return
                        }
                        // If onboarding is complete but no level yet, skip to the appropriate screen
                        if profile.onboardingCompleted == true {
                            let completedTestOnThisDevice = UserDefaults.standard.bool(forKey: "userHasCompletedPlacementTest")
                                && UserDefaults.standard.string(forKey: "completedTestUserId") == userId.uuidString
                            if completedTestOnThisDevice {
                                navigateToMain = true
                            } else if let startOption = profile.startOption {
                                if startOption == "startFromBeginning" {
                                    navigateToMain = true
                                } else if startOption == "findOutLevel" {
                                    navigateToTest = true
                                } else {
                                    navigateToProfile = true
                                }
                            } else {
                                navigateToProfile = true
                            }
                        } else {
                            navigateToProfile = true
                        }
                    }
                }
                
                // Also save to local database for backward compatibility
                let newUser = User(
                    id: userId,
                    username: username,
                    password: password,
                    languageLevel: "",
                    age: 0,
                    reasonForStudying: ""
                )
                _ = userDatabase.addUser(newUser)
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    let errorMsg = friendlyErrorMessage(for: error)
                    showError(message: errorMsg)
                    print("Registration error: \(error)")
                }
            }
        }
    }
    
    private func handleSignUp() async throws -> UUID {
        guard !username.isEmpty else {
            let msg = selectedLanguage == .english ? "Please enter a username" : "Введите имя пользователя"
            throw NSError(domain: "ValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        guard username.count >= 8 else {
            let msg = selectedLanguage == .english
                ? "Username must be at least 8 characters"
                : "Имя пользователя должно содержать не менее 8 символов"
            throw NSError(domain: "ValidationError", code: 4, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        guard !password.isEmpty else {
            let msg = selectedLanguage == .english ? "Please enter a password" : "Введите пароль"
            throw NSError(domain: "ValidationError", code: 2, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        guard password.count >= 8 else {
            let msg = selectedLanguage == .english
                ? "Password must be at least 8 characters"
                : "Пароль должен содержать не менее 8 символов"
            throw NSError(domain: "ValidationError", code: 5, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        guard password.contains(where: { $0.isNumber }) else {
            let msg = selectedLanguage == .english
                ? "Password must contain at least one number"
                : "Пароль должен содержать хотя бы одну цифру"
            throw NSError(domain: "ValidationError", code: 6, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        guard password == confirmPassword else {
            let msg = selectedLanguage == .english ? "Passwords do not match" : "Пароли не совпадают"
            throw NSError(domain: "ValidationError", code: 3, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        return try await SupabaseService.shared.registerUser(username: username, password: password)
    }
    
    private func handleLogIn() async throws -> UUID {
        guard !username.isEmpty else {
            let msg = selectedLanguage == .english ? "Please enter your username" : "Введите имя пользователя"
            throw NSError(domain: "ValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        guard !password.isEmpty else {
            let msg = selectedLanguage == .english ? "Please enter your password" : "Введите пароль"
            throw NSError(domain: "ValidationError", code: 2, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        return try await SupabaseService.shared.loginUser(username: username, password: password)
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    /// Maps any thrown error to a user-friendly message (no Supabase or technical wording).
    private func friendlyErrorMessage(for error: Error) -> String {
        let desc = error.localizedDescription
        let lower = desc.lowercased()
        
        // Validation errors (we set the message ourselves)
        if (error as NSError).domain == "ValidationError",
           let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String {
            return msg
        }
        
        // Known Supabase errors
        if let supabaseError = error as? SupabaseError {
            switch supabaseError {
            case .usernameAlreadyExists:
                return selectedLanguage == .english
                    ? "This username is already taken."
                    : "Это имя пользователя уже занято."
            case .userNotFound:
                return selectedLanguage == .english
                    ? "No account with this username."
                    : "Аккаунт с таким именем не найден."
            case .invalidPassword:
                return selectedLanguage == .english
                    ? "Incorrect password."
                    : "Неверный пароль."
            case .networkError:
                return selectedLanguage == .english
                    ? "Connection error. Please check your internet."
                    : "Ошибка соединения. Проверьте интернет."
            }
        }
        
        // Infer from error text (e.g. DB unique constraint or API message)
        if lower.contains("already exists") || lower.contains("duplicate") || lower.contains("unique") {
            return selectedLanguage == .english
                ? "This username is already taken."
                : "Это имя пользователя уже занято."
        }
        if lower.contains("user not found") || lower.contains("no user") {
            return selectedLanguage == .english
                ? "No account with this username."
                : "Аккаунт с таким именем не найден."
        }
        if lower.contains("invalid password") || lower.contains("incorrect password") {
            return selectedLanguage == .english
                ? "Incorrect password."
                : "Неверный пароль."
        }
        if lower.contains("network") || lower.contains("connection") || error is URLError {
            return selectedLanguage == .english
                ? "Connection error. Please check your internet."
                : "Ошибка соединения. Проверьте интернет."
        }
        
        // Generic fallback (no Supabase or technical details)
        return selectedLanguage == .english
            ? "Something went wrong. Please try again."
            : "Что-то пошло не так. Попробуйте снова."
    }
    
    // No email validation needed for username-based auth
}

