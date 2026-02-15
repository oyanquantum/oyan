//
//  EducationTeacherWordView.swift
//  OYAN App
//
//  Education goal – Question 1: "How do you say 'Teacher'?" – put word together from letters.
//

import SwiftUI

struct EducationTeacherWordView: View {
    let selectedLanguage: Language

    // 7 blanks for word мұғалім (teacher)
    @State private var blanks: [String?] = Array(repeating: nil, count: 7)
    // Pool: а л м р ғ і н ұ д ү + extra м (word is м-ұ-ғ-а-л-і-м)
    @State private var poolLetters: [String] = ["а", "л", "м", "м", "р", "ғ", "і", "н", "ұ", "д", "ү"].shuffled()
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var navigateToNext: Bool = false

    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")

    let correctWord = "мұғалім" // Teacher

    var questionText: String {
        selectedLanguage == .english ? "How do you say \"Teacher\"?" : "Как сказать «Учитель»?"
    }

    var initialBubbleText: String {
        selectedLanguage == .english ? "Put this word together now!" : "Собери это слово!"
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

    /// First index where blank is empty
    private var firstEmptyIndex: Int? {
        blanks.firstIndex(where: { $0 == nil })
    }

    var userWord: String {
        blanks.compactMap { $0 }.joined()
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)
            ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 20) {
                // Shift specialized test questions slightly downward
                Spacer().frame(height: 140)

                // Question in styled box
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(buttonColor)
                        .shadow(color: buttonColor.opacity(0.3), radius: 10, x: 0, y: 4)

                    Text(questionText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                }
                .frame(maxWidth: 320, maxHeight: 100)
                .padding(.vertical, 10)

                // Blanks: _ _ _ _ _ _ _
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        BlankLetterCell(
                            letter: blanks[index],
                            accentColor: buttonColor,
                            isFeedback: showFeedback,
                            isCorrectPosition: showFeedback && index < correctWord.count && blanks[index] == String(correctWord[correctWord.index(correctWord.startIndex, offsetBy: index)])
                        ) {
                            if showFeedback { return }
                            if let letter = blanks[index] {
                                blanks[index] = nil
                                poolLetters.append(letter)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Letter pool: tap a letter → it moves to first blank
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedLanguage == .english ? "Tap a letter to put it in the first blank" : "Нажми на букву, чтобы поставить её в первую пустую клетку")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 10) {
                        ForEach(Array(poolLetters.enumerated()), id: \.offset) { index, letter in
                            PoolLetterChip(letter: letter, accentColor: buttonColor) {
                                if showFeedback { return }
                                guard firstEmptyIndex != nil else { return }
                                poolLetters.remove(at: index)
                                if let first = blanks.firstIndex(where: { $0 == nil }) {
                                    blanks[first] = letter
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Not sure and Check; Continue overlays when feedback shown
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
                            if !showFeedback {
                                isCorrect = userWord == correctWord
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
                                        .fill(userWord.isEmpty || showFeedback ? buttonColor.opacity(0.45) : buttonColor)
                                )
                                .shadow(color: buttonColor.opacity(userWord.isEmpty || showFeedback ? 0.0 : 0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(userWord.isEmpty || showFeedback)
                    }

                    if showFeedback {
                        Button {
                            if isCorrect { recordSpecializedCorrect() }
                            navigateToNext = true
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
                .padding(.top, 20)

                Spacer()
            }

            // Eagle with speech bubble (same layout as other question views)
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
        .navigationDestination(isPresented: $navigateToNext) {
            EducationClassMeaningView(selectedLanguage: selectedLanguage)
        }
    }
}

// MARK: - Blank cell (empty or one letter; tap to return letter to pool)
private struct BlankLetterCell: View {
    let letter: String?
    let accentColor: Color
    let isFeedback: Bool
    let isCorrectPosition: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(letter ?? " ")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(letter == nil ? .secondary : .primary)
                .frame(width: 36, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(letter == nil ? Color.white : (isFeedback && isCorrectPosition ? Color.green.opacity(0.2) : Color.white))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(letter == nil ? accentColor.opacity(0.35) : accentColor.opacity(0.2), lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Letter chip in pool (tap to send to first blank)
private struct PoolLetterChip: View {
    let letter: String
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(letter)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(minWidth: 40, minHeight: 44)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(accentColor))
                .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// Simple flow layout for wrapping letter chips
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), anchor: .topLeading, proposal: ProposedViewSize(frame.size))
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        let totalHeight = y + rowHeight
        let totalWidth = min(maxWidth, subviews.isEmpty ? 0 : frames.map { $0.maxX }.max() ?? 0)
        return (CGSize(width: totalWidth, height: totalHeight), frames)
    }
}

#Preview {
    NavigationStack {
        EducationTeacherWordView(selectedLanguage: .english)
    }
}
