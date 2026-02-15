//
//  AchievementsView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI

enum Achievement: String, CaseIterable, Identifiable {
    case naturalConversation
    case essentialLexicon
    case consistentProgress
    
    var id: String { rawValue }
    
    var symbolName: String {
        switch self {
        case .naturalConversation: return "bubble.left.and.bubble.right.fill"
        case .essentialLexicon: return "book.fill"
        case .consistentProgress: return "chart.line.uptrend.xyaxis"
        }
    }
    
    func title(for language: Language) -> String {
        switch (self, language) {
        case (.naturalConversation, .english): return "Natural Conversation"
        case (.naturalConversation, .russian): return "Естественное общение"
            
        case (.essentialLexicon, .english): return "Essential Lexicon"
        case (.essentialLexicon, .russian): return "Основной словарь"
            
        case (.consistentProgress, .english): return "Consistent Progress"
        case (.consistentProgress, .russian): return "Постоянный прогресс"
        }
    }
    
    func description(for language: Language) -> String {
        switch (self, language) {
        case (.naturalConversation, .english): return "Master speaking and listening skills in a relaxed environment."
        case (.naturalConversation, .russian): return "Освойте навыки говорения и аудирования в расслабляющей обстановке."
            
        case (.essentialLexicon, .english): return "Build your word bank with high-frequency terms and practical idioms."
        case (.essentialLexicon, .russian): return "Создайте свой словарный запас с часто используемыми терминами и практическими идиомами."
            
        case (.consistentProgress, .english): return "Stay on track with personalized alerts and immersive daily activities."
        case (.consistentProgress, .russian): return "Оставайтесь на правильном пути с персонализированными напоминаниями и увлекательными ежедневными занятиями."
        }
    }
}

struct AchievementsView: View {
    let selectedLanguage: Language
    
    @State private var navigateToNext: Bool = false
    
    // Color scheme
    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")
    
    var speechBubbleText: String {
        selectedLanguage == .english
            ? "Here's what you can achieve!"
            : "Вот чего вы можете достичь!"
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
                    ForEach(Achievement.allCases) { achievement in
                        AchievementCard(
                            title: achievement.title(for: selectedLanguage),
                            descriptionText: achievement.description(for: selectedLanguage),
                            symbolName: achievement.symbolName,
                            accentColor: buttonColor
                        )
                    }
                }
                .padding(.horizontal, 30)
                
                // Continue button
                Button {
                    navigateToNext = true
                } label: {
                    Text(continueButtonText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(buttonColor)
                        )
                        .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 30)
                .padding(.top, 12)

                Spacer()
            }
            
            // Eagle in upper right (independent)
            VStack {
                HStack {
                    Spacer()
                    Image("eagle_achievements")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 280)
                        .padding(.top, 50)
                        .padding(.trailing, -20)
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
                        .offset(x: -40, y: -2)
                    }
                    .padding(.top, 40)
                    .padding(.trailing, 60)
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToNext) {
            TimeSelectionView(selectedLanguage: selectedLanguage)
        }
    }
}

private struct AchievementCard: View {
    let title: String
    let descriptionText: String
    let symbolName: String
    let accentColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.title2)
                .frame(width: 32)
                .foregroundColor(accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(descriptionText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accentColor.opacity(0.35), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AchievementsView(selectedLanguage: .english)
        }
    }
}
