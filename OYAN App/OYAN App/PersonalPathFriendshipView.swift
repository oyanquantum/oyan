//
//  PersonalPathFriendshipView.swift
//  OYAN App
//
//  Communication & For Yourself path – Q3: "She values true friendship." – put sentence parts in order.
//

import SwiftUI

struct PersonalPathFriendshipView: View {
    let selectedLanguage: Language

    @State private var slots: [String?] = Array(repeating: nil, count: 4)
    @State private var poolParts: [String] = ["шынайы", "ол", "жақсы", "қадірлейді", "әрқашан", "достықты", "сенеді"].shuffled()
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var navigateToNext: Bool = false

    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")

    // Ол шынайы достықты қадірлейді (She values true friendship)
    let correctOrder = ["ол", "шынайы", "достықты", "қадірлейді"]

    var questionText: String {
        selectedLanguage == .english ? "She values true friendship." : "Она ценит настоящую дружбу."
    }

    var initialBubbleText: String {
        selectedLanguage == .english ? "Now build a sentence" : "Теперь составь предложение"
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

    private var firstEmptyIndex: Int? {
        slots.firstIndex(where: { $0 == nil })
    }

    var userOrderCorrect: Bool {
        guard slots.allSatisfy({ $0 != nil }) else { return false }
        return (0..<4).allSatisfy { slots[$0] == correctOrder[$0] }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)
            ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 20) {
                // Shift specialized test questions slightly downward
                Spacer().frame(height: 140)

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

                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        PersonalPathSlotCell(
                            part: slots[index],
                            accentColor: buttonColor,
                            isFeedback: showFeedback,
                            isCorrectPosition: showFeedback && index < correctOrder.count && slots[index] == correctOrder[index]
                        ) {
                            if showFeedback { return }
                            if let part = slots[index] {
                                slots[index] = nil
                                poolParts.append(part)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedLanguage == .english ? "Tap a part to put it in the first blank" : "Нажми на часть, чтобы поставить в первую пустую клетку")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    PersonalPathFlowLayout(spacing: 10) {
                        ForEach(Array(poolParts.enumerated()), id: \.offset) { index, part in
                            PersonalPathPoolChip(part: part, accentColor: buttonColor) {
                                if showFeedback { return }
                                guard firstEmptyIndex != nil else { return }
                                poolParts.remove(at: index)
                                if let first = slots.firstIndex(where: { $0 == nil }) {
                                    slots[first] = part
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

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
                                isCorrect = userOrderCorrect
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
                                        .fill(slots.allSatisfy { $0 != nil } == false || showFeedback ? buttonColor.opacity(0.45) : buttonColor)
                                )
                                .shadow(color: buttonColor.opacity(slots.allSatisfy { $0 != nil } == false || showFeedback ? 0.0 : 0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(!slots.allSatisfy { $0 != nil } || showFeedback)
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
            TestResultsView(selectedLanguage: selectedLanguage)
        }
    }
}

private struct PersonalPathSlotCell: View {
    let part: String?
    let accentColor: Color
    let isFeedback: Bool
    let isCorrectPosition: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(part ?? " ")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(part == nil ? .secondary : .primary)
                .frame(minWidth: 64, minHeight: 44)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(part == nil ? Color.white : (isFeedback && isCorrectPosition ? Color.green.opacity(0.2) : Color.white))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(part == nil ? accentColor.opacity(0.35) : accentColor.opacity(0.2), lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct PersonalPathPoolChip: View {
    let part: String
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(part)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(accentColor))
                .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private struct PersonalPathFlowLayout: Layout {
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
        PersonalPathFriendshipView(selectedLanguage: .english)
    }
}
