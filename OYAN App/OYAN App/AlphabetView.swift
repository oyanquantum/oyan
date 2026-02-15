//
//  AlphabetView.swift
//  OYAN App
//
//  Kazakh alphabet: vowels (hard / soft) and consonants. Tap a letter to hear its sound (Kazakh TTS).
//

import SwiftUI

// MARK: - Kazakh alphabet data (Cyrillic)
// Hard vowels (back): а, о, у, ұ, ы
// Soft vowels (front): ә, е, і, ө, ү — plus и, ё, э, ю, я
// Consonants: the rest
private let hardVowels = ["А", "О", "У", "Ұ", "Ы"]
private let softVowels = ["Ә", "Е", "І", "Ө", "Ү", "И", "Ё", "Э", "Ю", "Я"]
private let consonants = ["Б", "В", "Г", "Ғ", "Д", "Ж", "З", "Й", "К", "Қ", "Л", "М", "Н", "Ң", "П", "Р", "С", "Т", "Ф", "Х", "Һ", "Ц", "Ч", "Ш", "Щ", "Ь", "Ъ"]

/// Alphabet pronunciation: how each letter is recited (e.g. Ц = "цэ", Ю = "йу").
private let alphabetPronunciation: [String: String] = [
    "А": "а", "О": "о", "У": "у", "Ұ": "ұ", "Ы": "ы",
    "Ә": "ә", "Е": "е", "І": "і", "Ө": "ө", "Ү": "ү",
    "И": "и", "Ё": "йо", "Э": "э", "Ю": "йу", "Я": "йа",
    "Б": "бэ", "В": "вэ", "Г": "гэ", "Ғ": "ға", "Д": "дэ",
    "Ж": "жэ", "З": "зэ", "Й": "й", "К": "ка", "Қ": "қа",
    "Л": "эль", "М": "эм", "Н": "эн", "Ң": "ңа", "П": "пэ",
    "Р": "эр", "С": "эс", "Т": "тэ", "Ф": "эф", "Х": "ха",
    "Һ": "һа", "Ц": "цэ", "Ч": "че", "Ш": "ша", "Щ": "ща",
    "Ь": "жіңішке", "Ъ": "қос белгі"
]

private func pronunciationForLetter(_ letter: String) -> String {
    alphabetPronunciation[letter] ?? letter.lowercased(with: Locale(identifier: "kk_KZ"))
}

struct AlphabetView: View {
    let selectedLanguage: Language

    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                titleSection

                // Vowels — Hard
                letterSection(
                    title: selectedLanguage == .english ? "Vowels — Hard" : "Гласные — твёрдые",
                    subtitle: nil,
                    letters: hardVowels
                )

                // Vowels — Soft
                letterSection(
                    title: selectedLanguage == .english ? "Vowels — Soft" : "Гласные — мягкие",
                    subtitle: nil,
                    letters: softVowels
                )

                // Consonants
                letterSection(
                    title: selectedLanguage == .english ? "Consonants" : "Согласные",
                    subtitle: nil,
                    letters: consonants
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(backgroundColor)
    }

    private var titleSection: some View {
        Text(selectedLanguage == .english ? "Alphabet" : "Алфавит")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }

    private func letterSection(title: String, subtitle: String?, letters: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            let columns = [
                GridItem(.adaptive(minimum: 52), spacing: 12)
            ]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(letters, id: \.self) { letter in
                    LetterBox(letter: letter, accentColor: buttonColor) {
                        let toSpeak = pronunciationForLetter(letter)
                        Task { await KazakhAudioButton.play(text: toSpeak) }
                    }
                }
            }
        }
    }
}

// MARK: - Letter box (tappable)
private struct LetterBox: View {
    let letter: String
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(letter)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(accentColor)
                .frame(minWidth: 48, minHeight: 48)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct AlphabetView_Previews: PreviewProvider {
    static var previews: some View {
        AlphabetView(selectedLanguage: .english)
    }
}
