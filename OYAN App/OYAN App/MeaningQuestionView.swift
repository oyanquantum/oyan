//
//  MeaningQuestionView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI

struct MeaningQuestionView: View {
    let selectedLanguage: Language
    
    @State private var selectedAnswer: String? = nil
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var navigateToQ6: Bool = false
    @State private var navigateToTravellingQ1: Bool = false
    @State private var navigateToWorkQ1: Bool = false
    @State private var navigateToPersonalQ1: Bool = false
    @State private var navigateToResults: Bool = false
    
    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")
    
    // "A stick has two ends" = Everything has pros and cons
    let proverb = "Таяқтың екі ұшы бар"
    
    var options: [String] {
        selectedLanguage == .english
            ? ["Every decision involves risk", "Everything has pros and cons", "Nothing is permanent", "Opportunities come and go"]
            : ["Каждое решение связано с риском", "У всего есть плюсы и минусы", "Ничто не вечно", "Возможности приходят и уходят"]
    }
    
    var correctAnswer: String {
        selectedLanguage == .english ? "Everything has pros and cons" : "У всего есть плюсы и минусы"
    }
    
    var initialBubbleText: String {
        selectedLanguage == .english ? "Choose the correct meaning" : "Выбери правильное значение"
    }
    
    var checkButtonText: String { selectedLanguage == .english ? "Check" : "Проверить" }
    var notSureButtonText: String { selectedLanguage == .english ? "Not sure" : "Не уверен" }
    var continueButtonText: String { selectedLanguage == .english ? "Continue" : "Продолжить" }
    var correctText: String { selectedLanguage == .english ? "Correct" : "Правильно" }
    var incorrectText: String { selectedLanguage == .english ? "Incorrect" : "Неправильно" }
    
    var eagleImageName: String {
        showFeedback ? (isCorrect ? "eagle_happy" : "eagle_sad") : "eagle_reason"
    }
    
    var eagleBubbleText: String {
        if !showFeedback { return initialBubbleText }
        return isCorrect
            ? (selectedLanguage == .english ? "Great job!" : "Отлично!")
            : (selectedLanguage == .english ? "Oops, you'll do better next time" : "Упс, в следующий раз получится лучше")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)
            ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Shift content slightly downward so the orange box,
                // options, and buttons sit lower on screen (same feel as lessons)
                Spacer().frame(height: 140)
                
                // Proverb in styled box (same style as first question)
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(buttonColor)
                        .shadow(color: buttonColor.opacity(0.3), radius: 10, x: 0, y: 4)
                    
                    Text(proverb)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                }
                .frame(maxWidth: 320, maxHeight: 120)
                .padding(.vertical, 10)
                
                // Multiple choice options
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        MeaningAnswerButton(
                            text: option,
                            isSelected: selectedAnswer == option,
                            accentColor: buttonColor,
                            showAsCorrect: showFeedback && option == correctAnswer,
                            showAsWrong: showFeedback && !isCorrect && option == selectedAnswer
                        ) {
                            if !showFeedback { selectedAnswer = option }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // Not sure and Check buttons; Continue overlays when feedback shown
                ZStack(alignment: .center) {
                    HStack(spacing: 12) {
                        Button {
                            if !showFeedback {
                                isCorrect = false
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showFeedback = true }
                            }
                        } label: {
                            Text(notSureButtonText)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(showFeedback ? buttonColor.opacity(0.45) : buttonColor)
                                )
                                .shadow(color: buttonColor.opacity(showFeedback ? 0.0 : 0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(showFeedback)
                        
                        Button {
                            if selectedAnswer != nil && !showFeedback {
                                isCorrect = selectedAnswer == correctAnswer
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showFeedback = true }
                            }
                        } label: {
                            Text(checkButtonText)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedAnswer == nil || showFeedback ? buttonColor.opacity(0.45) : buttonColor)
                                )
                                .shadow(color: buttonColor.opacity(selectedAnswer == nil || showFeedback ? 0.0 : 0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedAnswer == nil || showFeedback)
                    }
                    
                    if showFeedback {
                        Button { handleQ5Continue() } label: {
                            Text(continueButtonText)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 12).fill(buttonColor))
                                .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                Spacer()
            }
            
            // Eagle with speech bubble (same positions as first question)
            VStack {
                HStack {
                    Spacer()
                    ZStack(alignment: .topTrailing) {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(eagleBubbleText)
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
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
                            .offset(x: -40, y: -2)
                        }
                        .padding(.top, showFeedback && !isCorrect ? -58 : -50)
                        .padding(.trailing, showFeedback && !isCorrect ? 70 : 95)
                        
                        Image(eagleImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                maxWidth: showFeedback ? (isCorrect ? 300 : 260) : 350,
                                maxHeight: showFeedback ? (isCorrect ? 300 : 260) : 350
                            )
                            .padding(.top, showFeedback ? (isCorrect ? -20 : -25) : -90)
                            .padding(.trailing, showFeedback ? (isCorrect ? -20 : 15) : -35)
                    }
                }
                Spacer()
            }
            .padding(.top, 40)
            .allowsHitTesting(false)
            
        }
            Spacer()
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToQ6) {
            EducationTeacherWordView(selectedLanguage: selectedLanguage)
        }
        .navigationDestination(isPresented: $navigateToTravellingQ1) {
            TravellingAirportView(selectedLanguage: selectedLanguage)
        }
        .navigationDestination(isPresented: $navigateToWorkQ1) {
            WorkWordView(selectedLanguage: selectedLanguage)
        }
        .navigationDestination(isPresented: $navigateToPersonalQ1) {
            PersonalPathHealthView(selectedLanguage: selectedLanguage)
        }
        .navigationDestination(isPresented: $navigateToResults) {
            TestResultsView(selectedLanguage: selectedLanguage)
        }
    }
    
    /// Q5 Next: record G for Q5, then branch by reason or go to results.
    private func handleQ5Continue() {
        if isCorrect { recordGeneralCorrect() }
        let selectedReason = UserDefaults.standard.string(forKey: "selectedReasonForStudying")
        
        if selectedReason == KazakhLearningReason.education.rawValue {
            navigateToQ6 = true
        } else if selectedReason == KazakhLearningReason.travelling.rawValue {
            navigateToTravellingQ1 = true
        } else if selectedReason == KazakhLearningReason.workBusiness.rawValue {
            navigateToWorkQ1 = true
        } else if selectedReason == KazakhLearningReason.communication.rawValue || selectedReason == KazakhLearningReason.forYourself.rawValue {
            navigateToPersonalQ1 = true
        } else {
            navigateToResults = true
        }
    }
}

private struct MeaningAnswerButton: View {
    let text: String
    let isSelected: Bool
    let accentColor: Color
    var showAsCorrect: Bool = false
    var showAsWrong: Bool = false
    let onTap: () -> Void

    private var fillColor: Color {
        if showAsCorrect { return Color.green }
        if showAsWrong { return Color.red }
        return isSelected ? accentColor : Color.white
    }
    private var strokeColor: Color {
        if showAsCorrect { return Color.green }
        if showAsWrong { return Color.red }
        return accentColor.opacity(isSelected ? 0 : 0.35)
    }
    private var textColor: Color {
        if showAsCorrect || showAsWrong { return .white }
        return isSelected ? .white : .primary
    }

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.headline)
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 14).fill(fillColor))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(strokeColor, lineWidth: 2))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MeaningQuestionView(selectedLanguage: .english)
    }
}
