//
//  VocabularyView.swift
//  OYAN App
//
//  Learned words with translation. Fills as the user completes lessons.
//

import SwiftUI

struct VocabularyView: View {
    let selectedLanguage: Language

    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")

    @State private var entries: [VocabularyEntry] = []

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            VStack(spacing: 0) {
                Text(selectedLanguage == .english ? "Vocabulary" : "Словарь")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                if entries.isEmpty {
                    emptyState
                } else {
                    wordList
                }
            }
            .task {
                let uid: UUID? = {
                    guard let s = UserDefaults.standard.string(forKey: "currentUserId") else { return nil }
                    return UUID(uuidString: s)
                }()
                entries = await loadVocabulary(userId: uid)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed.fill")
                .font(.system(size: 64))
                .foregroundColor(buttonColor)
            Text(selectedLanguage == .english ? "No words yet" : "Пока нет слов")
                .font(.title3)
                .foregroundColor(.secondary)
            Text(selectedLanguage == .english ? "Complete lessons to add words here." : "Проходите уроки — новые слова появятся здесь.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var wordList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(entries) { entry in
                    HStack(alignment: .center, spacing: 16) {
                        Text(entry.word)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(entry.translation(english: selectedLanguage == .english))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(buttonColor.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                }
            }
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    VocabularyView(selectedLanguage: .english)
}
