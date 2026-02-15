//
//  MatchingEndingsQuestionView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI

struct MatchingEndingsQuestionView: View {
    let selectedLanguage: Language
    
    // Slots: which ending is placed next to each sentence (user moves endings here)
    @State private var slots: [String?] = [nil, nil, nil, nil]
    // Which ending is currently "in hand" (picked from pool or from a slot)
    @State private var selectedEnding: String? = nil
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var navigateToPlural: Bool = false
    
    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")
    
    let stems = ["Мен оқушы___", "Сен оқушы___", "Біз оқушы___", "Сіз оқушы___"]
    let endings = ["мын", "сың", "сыз", "мыз"]
    let correctPairings = ["мын", "сың", "мыз", "сыз"]
    
    // Endings not yet placed in any slot (still in the "pool" to move)
    var poolEndings: [String] {
        endings.filter { e in !slots.contains(e) }
    }
    
    var initialBubbleText: String {
        selectedLanguage == .english ? "Now try matching these" : "Теперь подбери окончания"
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
    
    var allSlotsFilled: Bool { slots.allSatisfy { $0 != nil } }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)
            ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                    Spacer().frame(height: 180)
                    
                    // 4 sentences, each with a slot (place ending here)
                    VStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { index in
                            SentenceSlotRow(
                                stem: stems[index],
                                placedEnding: slots[index],
                                correctEnding: correctPairings[index],
                                buttonColor: buttonColor,
                                isFeedback: showFeedback,
                                isSelected: selectedEnding != nil && slots[index] == nil
                            ) {
                                if showFeedback { return }
                                if let current = slots[index] {
                                    // Pick ending back from slot
                                    selectedEnding = current
                                    slots[index] = nil
                                } else if let holding = selectedEnding {
                                    // Place ending in this slot
                                    slots[index] = holding
                                    selectedEnding = nil
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Pool: endings still to be moved (tap to pick up)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedLanguage == .english ? "Endings (tap one, then tap a sentence slot to place it)" : "Окончания (нажми на одно, затем на слот)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(poolEndings, id: \.self) { ending in
                                PoolChip(
                                    text: ending,
                                    buttonColor: buttonColor,
                                    isSelected: selectedEnding == ending
                                ) {
                                    if showFeedback { return }
                                    if selectedEnding == ending {
                                        selectedEnding = nil
                                    } else {
                                        selectedEnding = ending
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
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
                                    .background(RoundedRectangle(cornerRadius: 12).fill(showFeedback ? buttonColor.opacity(0.45) : buttonColor))
                                    .shadow(color: buttonColor.opacity(showFeedback ? 0 : 0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                            .disabled(showFeedback)
                            
                            Button {
                                if allSlotsFilled && !showFeedback {
                                    isCorrect = (0..<4).allSatisfy { slots[$0] == correctPairings[$0] }
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showFeedback = true }
                                }
                            } label: {
                                Text(checkButtonText)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(!allSlotsFilled || showFeedback ? buttonColor.opacity(0.45) : buttonColor))
                                    .shadow(color: buttonColor.opacity(!allSlotsFilled || showFeedback ? 0 : 0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                            .disabled(!allSlotsFilled || showFeedback)
                        }
                        
                        if showFeedback {
                            Button {
                                if isCorrect { recordGeneralCorrect() }
                                navigateToPlural = true
                            } label: {
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
                    .padding(.top, 24)
                    
                    Spacer().frame(height: 40)
                }
            
            // Eagle + bubble (same layout as LanguageTestView)
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
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2))
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
                        .padding(.top, showFeedback ? (isCorrect ? 10 : 6) : 22)
                        .padding(.trailing, showFeedback && !isCorrect ? 70 : 95)
                        
                        Image(eagleImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: showFeedback ? (isCorrect ? 300 : 260) : 350, maxHeight: showFeedback ? (isCorrect ? 300 : 260) : 350)
                            .padding(.top, showFeedback ? (isCorrect ? 40 : 35) : -23)
                            .padding(.trailing, showFeedback ? (isCorrect ? -20 : 15) : -35)
                    }
                }
                Spacer()
            }
            .allowsHitTesting(false)
            
        }
            Spacer()
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToPlural) {
            PluralQuestionView(selectedLanguage: selectedLanguage)
        }
    }
}

// One sentence row: stem + slot (empty or filled with an ending chip). Tap slot to place or pick up.
private struct SentenceSlotRow: View {
    let stem: String
    let placedEnding: String?
    let correctEnding: String
    let buttonColor: Color
    let isFeedback: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(stem)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(minWidth: 110, alignment: .leading)
            
            // Slot: empty or filled with ending (tap to place or pick up)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                RoundedRectangle(cornerRadius: 12)
                    .stroke(buttonColor.opacity(placedEnding == nil ? 0.5 : 0.3), lineWidth: 2)
                
                if let ending = placedEnding {
                    let correct = ending == correctEnding
                    Text(ending)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isFeedback ? (correct ? Color.green : Color.red) : buttonColor)
                        )
                } else {
                    Text("—")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: 80, minHeight: 44)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? buttonColor : Color.clear, lineWidth: 2))
    }
}

// Chip in the pool: tap to pick up (or deselect)
private struct PoolChip: View {
    let text: String
    let buttonColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? buttonColor : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(buttonColor, lineWidth: isSelected ? 0 : 2)
                )
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MatchingEndingsQuestionView(selectedLanguage: .english)
    }
}
