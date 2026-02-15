//
//  VocabularyStorage.swift
//  OYAN App
//
//  Learned words: stored per user, filled when completing a lesson.
//

import Foundation

struct VocabularyEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var word: String           // Kazakh
    var translationEn: String
    var translationRu: String
    var lessonIndex: Int       // cloud index 1...11

    init(id: UUID = UUID(), word: String, translationEn: String, translationRu: String, lessonIndex: Int) {
        self.id = id
        self.word = word
        self.translationEn = translationEn
        self.translationRu = translationRu
        self.lessonIndex = lessonIndex
    }

    func translation(english: Bool) -> String {
        english ? translationEn : translationRu
    }
}

// MARK: - Words introduced per lesson (cloud index 1...11). Filled when user completes that lesson.
enum LessonVocabulary {
    /// For each cloud index, list of (Kazakh word, English translation, Russian translation).
    static let wordsByLesson: [Int: [(word: String, en: String, ru: String)]] = [
        1: [
            ("қазақ тілі", "Kazakh language", "казахский язык"),
            ("сингармонизм", "synharmonism", "сингармонизм"),
        ],
        2: [
            ("дауысты", "vowels", "гласные"),
            ("дауыссыз", "consonants", "согласные"),
        ],
        3: [
            ("бас", "head", "голова"),
            ("доп", "ball", "мяч"),
            ("қыз", "girl", "девушка"),
            ("кет", "go", "идти"),
            ("көз", "eye", "глаз"),
            ("сәт", "moment", "момент"),
            ("алма", "apple", "яблоко"),
        ],
        4: [], // Unit 1 Test – no new words
        5: [
            ("Сәлем", "Hello (informal)", "Привет"),
            ("сәлеметсіз бе", "Hello (formal)", "Здравствуйте"),
            ("Сау бол", "Goodbye (informal)", "Пока"),
            ("сау болыңыз", "Goodbye (formal)", "До свидания"),
        ],
        6: [
            ("мұғалім", "teacher", "учитель"),
            ("сыныптасы", "classmate", "одноклассник"),
        ],
        7: [], // Unit 2 Test
        8: [
            ("мен", "I", "я"),
            ("сен", "you (informal)", "ты"),
            ("оқушы", "student", "ученик"),
        ],
        9: [
            ("мың", "my ending (e.g. мұғаліммін)", "окончание «я»"),
            ("сың", "your ending (e.g. оқушысың)", "окончание «ты»"),
        ],
        10: [], // Usage lesson – review
        11: [], // Unit 3 Test
    ]

    static func words(forLesson cloudIndex: Int) -> [(word: String, en: String, ru: String)] {
        wordsByLesson[cloudIndex] ?? []
    }
}

// MARK: - Persist vocabulary (Supabase primary, UserDefaults fallback)
// Per-user keys so different people on the same device see their own vocabulary.
private func vocabularyKey(for userId: UUID?) -> String {
    if let uid = userId {
        return "oyan_vocabulary_v2_\(uid.uuidString)"
    }
    return "oyan_vocabulary_v2_anon"
}

/// Load from UserDefaults (local cache / fallback when offline). Scoped by userId.
func loadVocabularyLocal(userId: UUID?) -> [VocabularyEntry] {
    let key = vocabularyKey(for: userId)
    guard let data = UserDefaults.standard.data(forKey: key),
          let decoded = try? JSONDecoder().decode([VocabularyEntry].self, from: data) else {
        return []
    }
    return decoded
}

func saveVocabularyLocal(_ entries: [VocabularyEntry], userId: UUID?) {
    guard let data = try? JSONEncoder().encode(entries) else { return }
    UserDefaults.standard.set(data, forKey: vocabularyKey(for: userId))
}

/// Load vocabulary: from Supabase when userId present, else from user-scoped local storage.
/// Each user's vocabulary is stored separately (by level/lessons completed).
func loadVocabulary(userId: UUID?) async -> [VocabularyEntry] {
    if let userId = userId {
        do {
            let entries = try await SupabaseService.shared.fetchVocabulary(userId: userId)
            if !entries.isEmpty {
                saveVocabularyLocal(entries, userId: userId)
                return entries
            }
            // New user: no vocab in Supabase. Return empty; do NOT upload another user's local data.
            return []
        } catch {
            return loadVocabularyLocal(userId: userId)
        }
    }
    return loadVocabularyLocal(userId: nil)
}

/// Call when the user completes a lesson (e.g. taps "Back to lessons" on the results screen).
/// Adds that lesson's words to vocabulary if not already present. Saves to Supabase and local.
func addVocabularyWordsForLesson(cloudIndex: Int, userId: UUID?) async {
    let newWords = LessonVocabulary.words(forLesson: cloudIndex)
    guard !newWords.isEmpty else { return }

    var entries = loadVocabularyLocal(userId: userId)
    let existingWords = Set(entries.map { $0.word.lowercased() })
    var toAdd: [VocabularyEntry] = []

    for item in newWords {
        if existingWords.contains(item.word.lowercased()) { continue }
        let entry = VocabularyEntry(
            word: item.word,
            translationEn: item.en,
            translationRu: item.ru,
            lessonIndex: cloudIndex
        )
        entries.append(entry)
        toAdd.append(entry)
    }

    guard !toAdd.isEmpty else { return }
    saveVocabularyLocal(entries, userId: userId)

    if let userId = userId {
        try? await SupabaseService.shared.addVocabularyEntries(userId: userId, entries: toAdd)
    }
}
