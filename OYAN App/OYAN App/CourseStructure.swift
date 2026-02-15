//
//  CourseStructure.swift
//  OYAN App
//
//  Structure of units and lessons. 3 units: 8 lesson clouds + 3 golden (unit tests).
//

import Foundation

/// One node on the cloud path: either a lesson or a unit test.
struct CloudNode: Identifiable {
    let id: Int
    let unitIndex: Int      // 1-based
    let isTest: Bool
    let summary: String     // Sent to AI to generate content

    var displayTitle: String {
        if isTest { return "Unit \(unitIndex) Test" }
        return "Lesson \(id)"
    }
}

/// Key for storing current lesson progress. Per-user so different accounts have separate progression.
func currentLessonStorageKey(userId: UUID?) -> String {
    if let uid = userId {
        return "oyan_current_lesson_v2_\(uid.uuidString)"
    }
    return "oyan_current_lesson_v2_anon"
}

/// Fixed structure: 8 lessons + 3 unit tests. Golden clouds at indices 4, 7, 11 (1-based).
enum CourseStructure {
    /// Total clouds: 8 lessons + 3 tests = 11
    static let totalClouds = 11

    /// Cloud index (1...11) -> CloudNode. Clouds 4, 7, 11 are golden (unit tests).
    static func node(for cloudIndex: Int) -> CloudNode? {
        guard cloudIndex >= 1 && cloudIndex <= totalClouds else { return nil }
        let node = allNodes[cloudIndex - 1]
        return node
    }

    /// All 11 nodes in order (bottom to top on the path).
    static let allNodes: [CloudNode] = [
        // Unit 1 (clouds 1–4: lessons 1–3 + test)
        CloudNode(id: 1, unitIndex: 1, isTest: false, summary: "Unit 1, Lesson 1: Tell about the Kazakh language. Synharmonism is the basis. Comparing language to music."),
        CloudNode(id: 2, unitIndex: 1, isTest: false, summary: "Unit 1, Lesson 2: Sounds."),
        CloudNode(id: 3, unitIndex: 1, isTest: false, summary: "Unit 1, Lesson 3: First law of synharmonism (a soft vowel creates a soft syllable, a hard vowel creates a hard syllable). Pronouncing бас, доп, қыз, кет, көз, сәт."),
        CloudNode(id: 4, unitIndex: 1, isTest: true,  summary: "Unit 1 Test: Kazakh language introduction, synharmonism basis, sounds, first law of synharmonism, pronouncing бас, доп, қыз, кет, көз, сәт."),
        // Unit 2 (clouds 5–7: lessons 4–5 + test)
        CloudNode(id: 5, unitIndex: 2, isTest: false, summary: "Unit 2, Lesson 1: Greeting and farewell (Сәлем, сәлеметсіз бе. Сау бол, сау болыңыз)."),
        CloudNode(id: 6, unitIndex: 2, isTest: false, summary: "Unit 2, Lesson 2: First vocabulary (purpose related, e.g. education: мұғалім, сыныптасы). First usage of greeting and farewell (мұғалім - сәлеметсіз бе, сыныптасы - сәлем)."),
        CloudNode(id: 7, unitIndex: 2, isTest: true,  summary: "Unit 2 Test: Greeting and farewell, first vocabulary (мұғалім, сыныптасы), usage of greetings."),
        // Unit 3 (clouds 8–11: lessons 6–8 + test)
        CloudNode(id: 8, unitIndex: 3, isTest: false, summary: "Unit 3, Lesson 1: Me and you (мен, сен) + Second vocabulary (e.g. оқушы)."),
        CloudNode(id: 9, unitIndex: 3, isTest: false, summary: "Unit 3, Lesson 2: Personal endings (мен: мың, мін, бын, бін, пын, пін. Сен: сың, сің). Personal endings are added to names, professions, verbs, nouns, numerals, adjectives."),
        CloudNode(id: 10, unitIndex: 3, isTest: false, summary: "Unit 3, Lesson 3: Usage (Мен мұғаліммін, сен оқушысың)."),
        CloudNode(id: 11, unitIndex: 3, isTest: true,  summary: "Unit 3 Test: Me and you (мен, сен), vocabulary (оқушы), personal endings, usage (Мен мұғаліммін, сен оқушысың)."),
    ]

    /// Indices (1-based) that are golden (unit tests).
    static let goldenCloudIndices: Set<Int> = [4, 7, 11]

    static func isGolden(cloudIndex: Int) -> Bool {
        goldenCloudIndices.contains(cloudIndex)
    }

    /// Summary of lessons the user has completed (clouds 1..<currentCloud). Used for chat level adaptation.
    static func priorLessonsSummary(upTo currentCloud: Int) -> String? {
        guard currentCloud > 1 else { return nil }
        let summaries = (1..<currentCloud).compactMap { node(for: $0)?.summary }
        guard !summaries.isEmpty else { return nil }
        return summaries.enumerated().map { "Lesson \($0.offset + 1): \($0.element)" }.joined(separator: "\n")
    }

    /// Section divider titles for the path (between units). Pass true for English, false for Russian.
    static func sectionDividers(english: Bool) -> [(y: CGFloat, title: String)] {
        let y1 = 0.99
        let y2 = (0.705 + 0.623) / 2
        let y3 = (0.459 + 0.377) / 2
        if english {
            return [
                (y1, "Unit 1: Sounds & synharmonism"),
                (y2, "Unit 2: Greeting & vocabulary"),
                (y3, "Unit 3: Me, you & personal endings"),
            ]
        } else {
            return [
                (y1, "Блок 1: Звуки и сингармонизм"),
                (y2, "Блок 2: Приветствие и словарь"),
                (y3, "Блок 3: Я, ты и личные окончания"),
            ]
        }
    }
}

// MARK: - Generated content (from Edge Function: Gemini + KazLLM, or bundled)

struct GeneratedLessonContent: Codable {
    var title: String
    var explanationSlides: [String]
    var examples: [String]
    var quiz: [GeneratedQuizItem]

    enum CodingKeys: String, CodingKey {
        case title
        case explanationSlides = "explanation_slides"
        case examples
        case quiz
    }

    /// Real lesson content for each cloud when API is unavailable. Pass english: true for English, false for Russian.
    static func bundled(for cloudIndex: Int, english: Bool = true) -> GeneratedLessonContent {
        if english { return bundledEnglish(for: cloudIndex) }
        return bundledRussian(for: cloudIndex)
    }

    private static func bundledEnglish(for cloudIndex: Int) -> GeneratedLessonContent {
        switch cloudIndex {
        case 1:
            return GeneratedLessonContent(
                title: "Vowel Harmony",
                explanationSlides: [
                    "Kazakh is a Turkic language spoken in Kazakhstan. One of its key features is synharmonism: vowels in a word 'agree' with each other - like notes in a melody.",
                    "Think of language as music: soft vowels go together, hard vowels go together. This makes words sound smooth and consistent.",
                    "Don't worry! In this lesson you don't need to understand the meaning, you just need to hear the difference between hard and soft sounds."
                ],
                examples: [],
                quiz: [
                    GeneratedQuizItem(question: "Достық  -  [Dostyq]", options: ["Do you hear? Both the first vowel (dOs) and the second (tYk) sound hard."], correctIndex: 0, points: 0),
                    GeneratedQuizItem(question: "Hard vowels in a word typically go with ...", options: ["Only one vowel", "No other vowel", "Soft vowels", "Other hard vowels"], correctIndex: 3, points: 1),
                    GeneratedQuizItem(question: "Which syllable sounds soft?", options: ["Кә - [Kä]", "Бо - [Bo]", "Сы - [Sı]", "Да - [Da]"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Connect by sound", options: ["Жү", "Мы", "сық", "рек"], correctIndex: 0, points: 2),
                ]
            )
        case 2:
            return GeneratedLessonContent(
                title: "Sounds in Kazakh",
                explanationSlides: [
                    "Kazakh has vowels and consonants. Vowels can be hard (back) or soft (front).",
                    "Hard vowels: А  [A],  О  [O],  У  [W],  Ұ [ U],  Ы  [I] \n\nSoft vowels: Ә  [Ä],  Е  [E],  І  [I],  Ө  [Ö],  Ү  [Ü],  Э  [É]\n\nUniversal: И  [I],  У  [W] \n\nThe type of vowel in a word determines which endings we use later."
                ],
                examples: ["Hard: а, о, у, ұ, ы", "Soft: ә, е, і, ө, ү"],
                quiz: [
                    GeneratedQuizItem(question: "Which is a hard (back) vowel in Kazakh?", options: ["ы", "і", "ө", "ү"], correctIndex: 0),
                    GeneratedQuizItem(question: "Which is a soft (front) vowel?", options: ["а", "о", "ө", "ұ"], correctIndex: 2),
                    GeneratedQuizItem(question: "Hard vowels in Kazakh include:", options: ["а, о, у, ұ, ы", "ә, е, і, ө, ү", "Only ы", "Only а"], correctIndex: 0),
                    GeneratedQuizItem(question: "Soft (front) vowels include:", options: ["ә, е, і, ө, ү", "а, о, у", "ы, ұ", "None"], correctIndex: 0),
                    GeneratedQuizItem(question: "The vowel ұ is:", options: ["Hard (back)", "Soft (front)", "Neither", "Both"], correctIndex: 0),
                    GeneratedQuizItem(question: "The vowel и is:", options: ["Soft (front)", "Hard (back)", "Consonant", "Both"], correctIndex: 3),
                    GeneratedQuizItem(question: "What determines which endings we use in Kazakh?", options: ["The type of vowel", "Word length", "First letter only", "Nothing"], correctIndex: 0),
                    GeneratedQuizItem(question: "Which letter is a soft vowel?", options: ["ү", "ы", "ұ", "а"], correctIndex: 0),
                ]
            )
        case 3:
            return GeneratedLessonContent(
                title: "Synharmonism 1",
                explanationSlides: [
                    "First law: a soft vowel creates a soft syllable; a hard vowel creates a hard syllable.\n\nSo one word usually has only hard vowels or only soft vowels.",
                    "Practice these words:\n\nБас - [bas]\nҚыз - [qiz]\nКет - [ket]\nКөз - [köz]\n\nTry to determine which of them are soft and which are hard."
                ],
                examples: [],
                quiz: [
                    GeneratedQuizItem(question: "In the word көз, the vowel is:", options: ["Soft (front)", "Hard (back)", "Neither", "Both"], correctIndex: 0),
                    GeneratedQuizItem(question: "Which word has hard vowels?", options: ["доп", "кет", "сәт", "көз"], correctIndex: 0),
                    GeneratedQuizItem(question: "Which word has soft vowels?", options: ["қыз", "бас", "доп", "None of these"], correctIndex: 3),
                    GeneratedQuizItem(question: "бас has ___ vowels.", options: ["Hard", "Soft", "No", "Mixed"], correctIndex: 0),
                    GeneratedQuizItem(question: "кет has ___ vowels.", options: ["Soft", "Hard", "No", "Mixed"], correctIndex: 0),
                    GeneratedQuizItem(question: "One word usually has:", options: ["Only hard or only soft vowels", "Mixed vowels always", "One vowel only", "No vowels"], correctIndex: 0),
                    GeneratedQuizItem(question: "қыз uses which type of vowels?", options: ["Soft", "Hard", "Neither", "Both"], correctIndex: 0),
                ]
            )
        case 4:
            return GeneratedLessonContent(
                title: "Unit 1 Test",
                explanationSlides: [
                    "This test checks what you learned in Unit 1:\n\nthe Kazakh language,\n\nsynharmonism,\n\nsounds,\n\nand the first law with words like бас, доп, қыз, кет, көз, сәт."
                ],
                examples: [],
                quiz: [
                    GeneratedQuizItem(question: "Synharmonism in Kazakh means:", options: ["Vowels in a word agree", "Only one vowel per word", "No vowels", "Only consonants agree"], correctIndex: 0),
                    GeneratedQuizItem(question: "Which word has soft vowels?", options: ["бас", "доп", "қыз", "None"], correctIndex: 3),
                    GeneratedQuizItem(question: "Hard vowels in Kazakh include:", options: ["а, о, у, ы", "і, ө, ү", "е, э", "ю, я"], correctIndex: 0),
                    GeneratedQuizItem(question: "Б_ркіт - [B_rkit]\nWhich vowel sounds better?", options: ["е", "ү", "ұ", "ө"], correctIndex: 2),
                    GeneratedQuizItem(question: "Which word has hard vowels?", options: ["доп", "кет", "көз", "сәт"], correctIndex: 0),
                    GeneratedQuizItem(question: "The first law says: soft vowel creates ___ syllable.", options: ["Soft", "Hard", "No", "Mixed"], correctIndex: 0),
                    GeneratedQuizItem(question: "Kazakh is a ___ language.", options: ["Turkic", "Slavic", "Romance", "Germanic"], correctIndex: 0),
                    GeneratedQuizItem(question: "Кіт_п - [Kit_p]\nWhich vowel sounds better?", options: ["а", "ү", "е", "э"], correctIndex: 0),
                    GeneratedQuizItem(question: "көз has ___ vowels.", options: ["Soft", "Hard", "No", "Mixed"], correctIndex: 0),
                    GeneratedQuizItem(question: "Soft vowels include:", options: ["ә, е, і, ө, ү", "а, о, у, ы", "Only ы", "Only а"], correctIndex: 0),
                    GeneratedQuizItem(question: "Synharmonism is compared to:", options: ["Music", "Math", "Colours", "Numbers"], correctIndex: 0),
                    GeneratedQuizItem(question: "Connect by sound", options: ["Мы", "Тү", "йе", "сық"], correctIndex: 0, points: 2),
                    GeneratedQuizItem(question: "Connect by sound", options: ["Ал", "Сә", "мұрт", "біз"], correctIndex: 0, points: 2),
                ]
            )
        case 5:
            return GeneratedLessonContent(
                title: "Greetings",
                explanationSlides: [
                    "**Сәлем** is a casual greeting, like \"Hi\" or \"Hello\". Use it with friends and family.\n\nIt's important to choose the right greeting in Kazakh to show respect. We'll learn formal and informal ways to say hello.",
                "**Сәлеметсіз бе** is a formal greeting. Use it with elders, teachers, or people you don't know well. It means \"Hello\" but shows respect.\n\nThink of it like \"Good morning/afternoon/evening\" in English. It's always a safe and polite choice.",
                "**Сау бол** means \"Goodbye\" in a casual way. Use it with friends and family when you're leaving.\n\nIt's similar to saying \"Bye\" or \"See you later\" in English. Keep it casual!",
                "**Сау болыңыз** is the formal way to say \"Goodbye\". Use it with elders, teachers, or people you want to show respect to.\n\nIt's like saying \"Goodbye\" in a more polite way. Remember to use it in formal situations."
                ],
                examples: ["Сәлем! — Hi!", "Сәлеметсіз бе? — Hello! (formal)", "Сау бол! — Goodbye! (informal)", "Сау болыңыз! — Goodbye! (formal)", "Сәлем, Әлия! — Hi, Aliya!", "Сәлеметсіз бе, апай? — Hello, teacher! (formal)"],
                quiz: [
                    GeneratedQuizItem(question: "Listen and choose the correct greeting.", options: ["Сәлем", "Сау бол", "Сәлеметсіз бе", "Сау болыңыз"], correctIndex: 0, points: 1, type: "listening", audioText: "Сәлем"),
                    GeneratedQuizItem(question: "Choose the formal greeting.", options: ["Сәлем", "Сәлеметсіз бе", "Сау бол", "Hi"], correctIndex: 1, points: 1),
                    GeneratedQuizItem(question: "Which greeting do you use with a friend?", options: ["Сәлеметсіз бе", "Сау болыңыз", "Сәлем", "None of the above"], correctIndex: 2, points: 1),
                    GeneratedQuizItem(question: "Translate: Goodbye! (formal)", options: ["Сәлем!", "Сау бол!", "Сәлеметсіз бе!", "Сау болыңыз!"], correctIndex: 3, points: 1),
                    GeneratedQuizItem(question: "Choose the informal farewell.", options: ["Сау бол", "Сау болыңыз", "Сәлеметсіз бе", "Сәлем"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Which farewell do you use with a teacher?", options: ["Сау бол", "Сәлем", "Сау болыңыз", "None of the above"], correctIndex: 2, points: 1),
                    GeneratedQuizItem(question: "Translate: Hello! (informal)", options: ["Сәлем!", "Сау бол!", "Сәлеметсіз бе!", "Сау болыңыз!"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "What does Сау бол mean?", options: ["Goodbye! (informal)", "Student", "Teacher", "Hello"], correctIndex: 0, points: 2, type: "multiple_choice"),
                    GeneratedQuizItem(question: "What does Сәлеметсіз бе mean?", options: ["Hello! (formal)", "Student", "Teacher", "Hello"], correctIndex: 0, points: 2, type: "multiple_choice")
                ]
            )
        case 6:
            return GeneratedLessonContent(
                title: "Жаңа сөздер (New Words)",
                explanationSlides: [
                    "Let's learn two new words: **мұғалім** (teacher) and **сыныптасы** (classmate). These are important for talking about school!",
                "**Мұғалім** means 'teacher'. You'll use this word to address your teachers. Remember to be respectful!\n\nUse **Сәлеметсіз бе** when greeting a teacher. It's the polite form of 'hello'.",
                "**Сыныптасы** means 'classmate'. These are the people you study with. It's great to be friendly with your classmates!\n\nUse **Сәлем** when greeting a classmate. It's the informal way to say 'hello'."
                ],
                examples: ["Мұғалім: Сәлеметсіз бе! — Teacher: Hello!", "Сыныптасы: Сәлем! — Classmate: Hi!"],
                quiz: [
                    GeneratedQuizItem(question: "Мұғалім is...", options: ["Teacher", "Student", "Friend"], correctIndex: 0, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Сыныптасы is...", options: ["Classmate", "Teacher", "Principal"], correctIndex: 0, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "How do you greet a teacher?", options: ["Сәлеметсіз бе", "Сәлем", "Сау бол"], correctIndex: 0, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "How do you greet a classmate?", options: ["Сәлем", "Сәлеметсіз бе", "Көріскенше"], correctIndex: 0, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "What does Мұғалім mean?", options: ["Teacher", "Classmate", "Student", "Hello"], correctIndex: 0, points: 2, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Choose the correct translation: Teacher", options: ["Мұғалім", "Оқушы", "Дос"], correctIndex: 0, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Choose the correct translation: Classmate", options: ["Сыныптасы", "Мұғалім", "Директор"], correctIndex: 0, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Fill in the blank: Hello (to a teacher) =  _______ бе", options: ["Сәлеметсіз", "Сәлем", "Рақмет"], correctIndex: 0, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Fill in the blank: Hi (to a classmate) = _______", options: ["Сәлем", "Сәлеметсіз бе", "Көріскенше"], correctIndex: 0, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Listening: Select the correct word.", options: ["Мұғалім", "Сыныптасы"], correctIndex: 0, points: 1, type: "listening", audioText: "Мұғалім")
                ]
            )
        case 7:
            return GeneratedLessonContent(
                title: "Unit 2 Test",
                explanationSlides: [
                    "This is a test to check your understanding of Units 1 and 2. It covers greetings, farewells, and basic vocabulary like **мұғалім** (teacher) and **сыныптасы** (classmate).\n\nRemember the difference between formal and informal greetings. Good luck!",
                "**Сәлем** is an informal greeting, used with friends and family. It's like saying 'Hi' or 'Hello' in English.\n\n**Сәлеметсіз бе** is a formal greeting, used with elders, teachers, or people you don't know well. It's like saying 'Good morning/afternoon/evening'.\n\nPay attention to context when choosing the right greeting!"
                ],
                examples: ["Сәлем, достар! — Hi, friends!", "Сәлеметсіз бе, апай? — Good morning/afternoon/evening, teacher?", "Сау бол! — Goodbye!", "Көріскенше! — See you later!"],
                quiz: [
                    GeneratedQuizItem(question: "How would you greet your teacher in the morning?", options: ["Сәлем!", "Сау бол!", "Көріскенше!", "Сәлеметсіз бе!"], correctIndex: 3, points: 1, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Which greeting is informal?", options: ["Сәлеметсіз бе?", "Сәлем!", "Рақмет!", "Көріскенше!"], correctIndex: 1, points: 1, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Complete the sentence: _____, достар! (Hi, friends!)", options: ["Сәлем", "Сәлем!", "Сау бол!", "Көріскенше!"], correctIndex: 0, points: 1, type: "fill_in_the_blank"),
                    GeneratedQuizItem(question: "Match the Kazakh word with its English translation.", options: ["Yes", "No"], correctIndex: 0, points: 3, type: "matching"),
                    GeneratedQuizItem(question: "What does 'Көріскенше!' mean?", options: ["Hello!", "Goodbye!", "See you later!", "Thank you!"], correctIndex: 2, points: 1, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Choose the correct greeting you hear.", options: ["Сәлем!", "Сәлеметсіз бе?", "Сау бол!", "Рақмет!"], correctIndex: 1, points: 1, type: "listening", audioText: "Сәлеметсіз бе?"),
                    GeneratedQuizItem(question: "'Сәлем' is a formal greeting.", options: ["Yes", "No"], correctIndex: 0, points: 1, type: "true_false"),
                    GeneratedQuizItem(question: "Complete the sentence: Сәлеметсіз _____, ағай? (Good morning/afternoon/evening, sir?)", options: ["бе", "Сәлем!", "Сау бол!", "Көріскенше!"], correctIndex: 0, points: 1, type: "fill_in_the_blank"),
                    GeneratedQuizItem(question: "What does Сәлем mean?", options: ["Hi", "Student", "Teacher", "Hello"], correctIndex: 0, points: 2, type: "multiple_choice"),
                    GeneratedQuizItem(question: "You are leaving school for the day. What do you say to your classmate?", options: ["Сәлеметсіз бе?", "Рақмет!", "Сау бол!", "Көріскенше!"], correctIndex: 2, points: 1, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Which word means 'teacher'?", options: ["Дос", "Мұғалім", "Сынып", "Оқушы"], correctIndex: 1, points: 1, type: "multiple_choice")
                ]
            )
        case 8:
            return GeneratedLessonContent(
                title: "Мен және Сен",
                explanationSlides: [
                    "**Мен** means \"I\" in Kazakh. It's used to refer to yourself. Remember this basic pronoun!\n\nFor example: **Мен оқушымын** (Men oqushymyn) - I am a student.",
                "**Сен** means \"you\" (singular, informal) in Kazakh. Use it when speaking to someone you know well, like a friend or family member.\n\nFor example: **Сен кімсің?** (Sen kimsing?) - Who are you?",
                "**Оқушы** means \"student\" in Kazakh. This is a useful noun to know. It applies to students of all ages.\n\nFor example: **Ол оқушы** (Ol oqushy) - He/She is a student.\n\nRemember that Kazakh does not have grammatical gender, so **ол** can mean he or she."
                ],
                examples: ["Мен — I", "Сен — You (informal, singular)", "Оқушы — Student", "Мен оқушымын — I am a student", "Сен оқушысың — You are a student (informal)", "Ол оқушы — He/She is a student", "Мен мұғаліммін — I am a teacher (from Unit 2)", "Сен мұғалімсің — You are a teacher (informal)"],
                quiz: [
                    GeneratedQuizItem(question: "Translate to Kazakh: I", options: ["Мен", "Оқушы", "Сен оқушысың", "Мұғалім"], correctIndex: 0, points: 1, type: "translate_to_kazakh"),
                    GeneratedQuizItem(question: "What does Сен mean?", options: ["You (informal)", "I am a student", "He/She is a student", "I"], correctIndex: 0, points: 1, type: "translate_to_english"),
                    GeneratedQuizItem(question: "Translate to Kazakh: Student", options: ["Оқушы", "Мен", "Сен оқушысың", "Мұғалім"], correctIndex: 0, points: 1, type: "translate_to_kazakh"),
                    GeneratedQuizItem(question: "What does Мен оқушымын mean?", options: ["I am a student", "You (informal)", "He/She is a student", "I"], correctIndex: 0, points: 2, type: "translate_to_english"),
                    GeneratedQuizItem(question: "Translate to Kazakh: You are a student (informal)", options: ["Сен оқушысың", "Мен", "Оқушы", "Мұғалім"], correctIndex: 0, points: 2, type: "translate_to_kazakh"),
                    GeneratedQuizItem(question: "What does Ол оқушы mean?", options: ["He/She is a student", "You (informal)", "I am a student", "I"], correctIndex: 0, points: 2, type: "translate_to_english"),
                    GeneratedQuizItem(question: "Listen and choose the correct word.", options: ["Мұғалім", "Оқушы", "Дәрігер"], correctIndex: 1, points: 2, type: "listening", audioText: "Оқушы"),
                    GeneratedQuizItem(question: "What does Мен mean?", options: ["I", "You (informal)", "Student", "Teacher"], correctIndex: 0, points: 2, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Fill in the blank: ____ оқушымын (I am a student)", options: ["Мен", "Оқушы", "Сен оқушысың", "Мұғалім"], correctIndex: 0, points: 1, type: "fill_in_the_blank")
                ]
            )
        case 9:
            return GeneratedLessonContent(
                title: "Personal Endings: Мен and Сен",
                explanationSlides: [
                    "This lesson introduces **personal endings** for **\"мен\" (I)** and **\"сен\" (you)**. These endings attach to nouns and adjectives to show who or what something *is*.\n\nThink of them as the Kazakh way of saying \"I am...\" or \"You are...\"",
                "When the word ends in a **hard consonant** or **vowel**, use the endings **-мын** (for \"мен\") and **-сың** (for \"сен\").**\n\nFor example: Мен студентпін (I am a student). Сен дәрігерсің (You are a doctor).",
                "When the word ends in a **soft consonant** or **vowel**, use the endings **-мін** (for \"мен\") and **-сің** (for \"сен\").**\n\nFor example: Мен мұғаліммін (I am a teacher). Сен әдемісің (You are beautiful).",
                "Remember: **-мын/-мін** are for **\"мен\"**, and **-сың/-сің** are for **\"сен\"**. Pay attention to whether the word ends in a hard or soft sound to choose the correct ending!"
                ],
                examples: ["Мен студентпін — I am a student.", "Сен дәрігерсің — You are a doctor.", "Мен мұғаліммін — I am a teacher.", "Сен әдемісің — You are beautiful.", "Мен қазақпын — I am Kazakh.", "Сен ақылдысың — You are smart."],
                quiz: [
                    GeneratedQuizItem(question: "Мен ... (мұғалім)", options: ["мұғаліммін", "мұғаліммін", "мұғалімсың", "мұғалімсің"], correctIndex: 0, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Сен ... (дәрігер)", options: ["дәрігермін", "дәрігерсың", "дәрігермін", "дәрігерсің"], correctIndex: 3, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Мен ... (студент)", options: ["студентпін", "студентмін", "студентсың", "студентсің"], correctIndex: 0, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Сен ... (ақылды)", options: ["ақылдымын", "ақылдысың", "ақылдымін", "ақылдысің"], correctIndex: 1, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Мен ... (қазақ)", options: ["қазақпын", "қазақмін", "қазақсың", "қазақсің"], correctIndex: 0, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Сен ... (әдемі)", options: ["әдемімін", "әдеміпін", "әдемісың", "әдемісің"], correctIndex: 3, type: "multiple_choice"),
                    GeneratedQuizItem(question: "Мен мұғаліммін", options: ["I am a student.", "You are a teacher.", "I am a teacher.", "You are a student."], correctIndex: 2, type: "listening", audioText: "Мен мұғаліммін"),
                    GeneratedQuizItem(question: "What does Мен дәрігермін mean?", options: ["I am a doctor.", "You are a student.", "Student", "Teacher"], correctIndex: 0, points: 2, type: "multiple_choice")
                ]
            )
        case 10:
            return GeneratedLessonContent(
                title: "Мен және Сен",
                explanationSlides: [
                    "This lesson focuses on using **personal pronouns** with **descriptive words**. We'll learn how to say \"I am a teacher\" and \"You are a student\" in Kazakh. \n\nRemember **Мен** (I) and **Сен** (You). These are fundamental to forming sentences about yourself and others.",
                "When describing yourself, use the suffix **-мін** after the descriptive word. For example, to say \"I am a teacher,\" you would say **Мен мұғаліммін**. \n\n**Мұғалім** means teacher. Adding **-мін** connects it to **Мен** (I).",
                "When describing someone else (using **Сен** - You), use the suffix **-сың** after the descriptive word. To say \"You are a student,\" you would say **Сен оқушысың**. \n\n**Оқушы** means student. The suffix **-сың** links the description to **Сен** (You).",
                "Let's recap! **Мен + descriptive word + -мін** (I am...). **Сен + descriptive word + -сың** (You are...). \n\nPractice these patterns to describe yourself and others using different words."
                ],
                examples: ["Мен дәрігермін — I am a doctor", "Сен студентсің — You are a student", "Мен жүргізушімін — I am a driver", "Сен әншісің — You are a singer"],
                quiz: [
                    GeneratedQuizItem(question: "Listen and choose the correct sentence.", options: ["Мен оқушымын", "Сен оқушысың", "Ол оқушы"], correctIndex: 1, points: 1, type: "listening", audioText: "Сен оқушысың"),
                    GeneratedQuizItem(question: "Мен дәрігер…", options: ["мін", "сің", "міз"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Сен мұғалім…", options: ["мін", "сің", "міз"], correctIndex: 1, points: 1),
                    GeneratedQuizItem(question: "I am a driver", options: ["Мен жүргізушімін", "Сен жүргізушісің", "Ол жүргізуші"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "You are a doctor", options: ["Мен дәрігермін", "Сен дәрігерсің", "Ол дәрігер"], correctIndex: 1, points: 1),
                    GeneratedQuizItem(question: "Мен студент…", options: ["мін", "сің", "міз"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Сен әнші…", options: ["мін", "сің", "міз"], correctIndex: 1, points: 1),
                    GeneratedQuizItem(question: "I am a singer", options: ["Мен әншімін", "Сен әншісің", "Ол әнші"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "You are a teacher", options: ["Мен мұғаліммін", "Сен мұғалімсің", "Ол мұғалім"], correctIndex: 1, points: 1)
                ]
            )
        case 11:
            return GeneratedLessonContent(
                title: "Unit 3 Test: Мен/Сен",
                explanationSlides: [
                    "This test covers **personal pronouns** and **personal endings** you learned in Unit 3. Remember how to use **Мен** and **Сен** correctly.\n\nPay close attention to the sentence structure and the appropriate endings for each pronoun.",
                "**Мен** means \"I\" and takes specific endings depending on the word. **Сен** means \"You\" (singular, informal) and has its own set of endings.\n\nReview the examples and practice questions to refresh your understanding of these concepts.",
                "Remember the words **оқушы** (student) and **мұғалім** (teacher). These are common words used with Мен and Сен.\n\nThink about how these words change when you add personal endings."
                ],
                examples: ["Мен мұғаліммін. — I am a teacher.", "Сен оқушысың. — You are a student.", "Мен дәрігермін. — I am a doctor.", "Сен доспын. — You are a friend."],
                quiz: [
                    GeneratedQuizItem(question: "Мен ...", options: ["оқушымын", "оқушысың", "оқушы", "оқушымыз"], correctIndex: 0, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Сен ...", options: ["мұғаліммін", "мұғалімсің", "мұғалім", "мұғалімбіз"], correctIndex: 1, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Translate: I am a student.", options: ["Сен оқушысың.", "Мен мұғаліммін.", "Мен оқушымын.", "Сен мұғалімсің."], correctIndex: 2, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Translate: You are a teacher.", options: ["Мен оқушымын.", "Сен мұғалімсің.", "Мен мұғаліммін.", "Сен оқушысың."], correctIndex: 1, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Fill in the blank: Мен дәрігер____.", options: ["мын", "сің", "мін", "біз"], correctIndex: 2, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Fill in the blank: Сен дос____.", options: ["мін", "сің", "мын", "біз"], correctIndex: 1, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Listening: Choose the correct sentence.", options: ["Сен мұғалімсің.", "Мен оқушымын.", "Сен оқушысың.", "Мен мұғаліммін."], correctIndex: 1, points: 2, type: "listening", audioText: "Мен оқушымын."),
                    GeneratedQuizItem(question: "Listening: Choose the correct sentence.", options: ["Мен оқушымын.", "Сен мұғалімсің.", "Сен оқушысың.", "Мен мұғаліммін."], correctIndex: 1, points: 2, type: "listening", audioText: "Сен мұғалімсің."),
                    GeneratedQuizItem(question: "Which pronoun means 'I'?", options: ["Сен", "Ол", "Мен", "Біз"], correctIndex: 2, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Which pronoun means 'You' (informal, singular)?", options: ["Мен", "Ол", "Сен", "Біз"], correctIndex: 2, points: 1, type: "mcq"),
                    GeneratedQuizItem(question: "Complete the sentence: Мен студент____.", options: ["сің", "мін", "пын", "біз"], correctIndex: 1, points: 1, type: "mcq")
                ]
            )
        default:
            return GeneratedLessonContent(
                title: "Lesson",
                explanationSlides: ["Content for this lesson."],
                examples: [],
                quiz: [GeneratedQuizItem(question: "What did you learn?", options: ["Key concept", "Nothing yet", "Review again"], correctIndex: 0)]
            )
        }
    }

    private static func bundledRussian(for cloudIndex: Int) -> GeneratedLessonContent {
        switch cloudIndex {
        case 1:
            return GeneratedLessonContent(
                title: "Гармония гласных",
                explanationSlides: [
                    "Казахский — тюркский язык, на котором говорят в Казахстане. Одна из главных черт — сингармонизм: гласные в слове «согласуются» друг с другом, как ноты в мелодии.",
                    "Представьте язык как музыку: мягкие гласные с мягкими, твёрдые с твёрдыми. Так слова звучат ровно и последовательно.",
                    ""  // Info 3 – текст и кнопки будут добавлены
                ],
                examples: [],
                quiz: [
                    GeneratedQuizItem(question: "Достық  -  [Dostyq]", options: ["Слышите? И первая гласная (дОс), и вторая (тЫк) звучат твёрдо."], correctIndex: 0, points: 0),
                    GeneratedQuizItem(question: "Твёрдые гласные в слове обычно с ...", options: ["Только одна гласная", "Без других гласных", "Мягкими гласными", "Другими твёрдыми гласными"], correctIndex: 3, points: 1),
                    GeneratedQuizItem(question: "Какий слог звучит мягко?", options: ["Кә - [Kä]", "Бо - [Bo]", "Сы - [Sı]", "Да - [Da]"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Соедини по звуку", options: ["Жү", "Мы", "сық", "рек"], correctIndex: 0, points: 2),
                ]
            )
        case 2:
            return GeneratedLessonContent(
                title: "Звуки в казахском",
                explanationSlides: [
                    "В казахском есть гласные и согласные. Гласные бывают твёрдыми (задние) и мягкими (передние).",
                    "Твёрдые гласные: А  [A],  О  [O],  У  [W],  Ұ [ U],  Ы  [I] \n\nМягкие гласные: Ә  [Ä],  Е  [E],  І  [I],  Ө  [Ö],  Ү  [Ü],  Э  [É]\n\nУниверсальные: И  [I],  У  [W] \n\nТип гласной в слове определяет, какие окончания мы будем использовать."
                ],
                examples: ["Твёрдые: а, о, у, ұ, ы", "Мягкие: ә, е, і, ө, ү"],
                quiz: [
                    GeneratedQuizItem(question: "Какая гласная твёрдая (задняя) в казахском?", options: ["ы", "і", "ө", "ү"], correctIndex: 0),
                    GeneratedQuizItem(question: "Какая гласная мягкая (передняя)?", options: ["а", "о", "ө", "ұ"], correctIndex: 2),
                    GeneratedQuizItem(question: "Твёрдые гласные в казахском — это:", options: ["а, о, у, ұ, ы", "ә, е, і, ө, ү", "Только ы", "Только а"], correctIndex: 0),
                    GeneratedQuizItem(question: "Мягкие (передние) гласные — это:", options: ["ә, е, і, ө, ү", "а, о, у", "ы, ұ", "Нет таких"], correctIndex: 0),
                    GeneratedQuizItem(question: "Гласная ұ — это:", options: ["Твёрдая (задняя)", "Мягкая (передняя)", "Ни то ни другое", "Обе"], correctIndex: 0),
                    GeneratedQuizItem(question: "Гласная и — это:", options: ["Мягкая (передняя)", "Твёрдая (задняя)", "Согласная", "Обе"], correctIndex: 3),
                    GeneratedQuizItem(question: "Что определяет окончания в казахском?", options: ["Тип гласной", "Длина слова", "Только первая буква", "Ничего"], correctIndex: 0),
                    GeneratedQuizItem(question: "Какая буква — мягкая гласная?", options: ["ү", "ы", "ұ", "а"], correctIndex: 0),
                ]
            )
        case 3:
            return GeneratedLessonContent(
                title: "Сингармонизм 1",
                explanationSlides: [
                    "Первый закон: мягкая гласная создаёт мягкий слог, твёрдая — твёрдый.\n\nПоэтому в одном слове обычно только твёрдые или только мягкие гласные.",
                    "Потренируйтесь:\n\nБас - [bas]\nҚыз - [qiz]\nКет - [ket]\nКөз - [köz]\n\nПостарайтесь определить, какие из них мягкие, а какие твёрдые."
                ],
                examples: [],
                quiz: [
                    GeneratedQuizItem(question: "В слове көз гласная:", options: ["Мягкая (передняя)", "Твёрдая (задняя)", "Ни то ни другое", "Обе"], correctIndex: 0),
                    GeneratedQuizItem(question: "В каком слове твёрдые гласные?", options: ["доп", "кет", "сәт", "көз"], correctIndex: 0),
                    GeneratedQuizItem(question: "В каком слове мягкие гласные?", options: ["қыз", "бас", "доп", "Ни в одном"], correctIndex: 3),
                    GeneratedQuizItem(question: "бас имеет гласные:", options: ["Твёрдые", "Мягкие", "Нет", "Смешанные"], correctIndex: 0),
                    GeneratedQuizItem(question: "кет имеет гласные:", options: ["Мягкие", "Твёрдые", "Нет", "Смешанные"], correctIndex: 0),
                    GeneratedQuizItem(question: "В одном слове обычно:", options: ["Только твёрдые или только мягкие гласные", "Всегда смешанные", "Одна гласная", "Нет гласных"], correctIndex: 0),
                    GeneratedQuizItem(question: "қыз — какие гласные?", options: ["Мягкие", "Твёрдые", "Ни те ни другие", "Оба типа"], correctIndex: 0),
                ]
            )
        case 4:
            return GeneratedLessonContent(
                title: "Тест. Блок 1",
                explanationSlides: [
                    "Этот тест проверяет блок 1:\n\nказахский язык,\n\nсингармонизм,\n\nзвуки,\n\nи первый закон (бас, доп, қыз, кет, көз, сәт)."
                ],
                examples: [],
                quiz: [
                    GeneratedQuizItem(question: "Сингармонизм в казахском значит:", options: ["Гласные в слове согласуются", "В слове одна гласная", "Нет гласных", "Согласуются согласные"], correctIndex: 0),
                    GeneratedQuizItem(question: "В каком слове мягкие гласные?", options: ["бас", "доп", "қыз", "Нет"], correctIndex: 3),
                    GeneratedQuizItem(question: "Твёрдые гласные в казахском:", options: ["а, о, у, ы", "і, ө, ү", "е, э", "ю, я"], correctIndex: 0),
                    GeneratedQuizItem(question: "Б_ркіт - [B_rkit]\nКакая гласная звучит лучше?", options: ["е", "ү", "ұ", "ө"], correctIndex: 2),
                    GeneratedQuizItem(question: "В каком слове твёрдые гласные?", options: ["доп", "кет", "көз", "сәт"], correctIndex: 0),
                    GeneratedQuizItem(question: "Первый закон: мягкая гласная создаёт ___ слог.", options: ["Мягкий", "Твёрдый", "Нет", "Смешанный"], correctIndex: 0),
                    GeneratedQuizItem(question: "Казахский — ___ язык.", options: ["Тюркский", "Славянский", "Романский", "Германский"], correctIndex: 0),
                    GeneratedQuizItem(question: "Кіт_п - [Kit_p]\nКакая гласная звучит лучше?", options: ["а", "ү", "е", "э"], correctIndex: 0),
                    GeneratedQuizItem(question: "көз имеет гласные:", options: ["Мягкие", "Твёрдые", "Нет", "Смешанные"], correctIndex: 0),
                    GeneratedQuizItem(question: "Мягкие гласные — это:", options: ["ә, е, і, ө, ү", "а, о, у, ы", "Только ы", "Только а"], correctIndex: 0),
                    GeneratedQuizItem(question: "Сингармонизм сравнивают с:", options: ["Музыкой", "Математикой", "Цветами", "Числами"], correctIndex: 0),
                    GeneratedQuizItem(question: "Соедини по звуку", options: ["Мы", "Тү", "йе", "сық"], correctIndex: 0, points: 2),
                    GeneratedQuizItem(question: "Соедини по звуку", options: ["Ал", "Сә", "мұрт", "біз"], correctIndex: 0, points: 2),
                ]
            )
        case 5:
            return GeneratedLessonContent(
                title: "Приветствие и прощание",
                explanationSlides: [
                    "Приветствие: Сәлем (неформально, «привет») или Сәлеметсіз бе (формально, «здравствуйте»). Послушайте, как они звучат.",
                    "Прощание: Сау бол (неформально) или Сау болыңыз (формально). Окончание -ыңыз делает форму вежливой.",
                    "С учителями и старшими — формальные формы. С друзьями и одноклассниками можно Сәлем и Сау бол."
                ],
                examples: ["Сәлем — привет", "Сәлеметсіз бе — здравствуйте (формально)", "Сау бол — пока", "Сау болыңыз — до свидания (формально)"],
                quiz: [
                    GeneratedQuizItem(question: "Сәлем  -  [Sälem]", options: ["Слышите? Неформальное приветствие, как «привет»."], correctIndex: 0, points: 0, type: "listening", audioText: "Сәлем"),
                    GeneratedQuizItem(question: "Как сказать «здравствуйте» формально?", options: ["Сәлеметсіз бе", "Сәлем", "Сау бол", "Сау болыңыз"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Сау болыңыз значит:", options: ["Здравствуйте", "До свидания (формально)", "Спасибо", "Пожалуйста"], correctIndex: 1, points: 1),
                    GeneratedQuizItem(question: "Сәлем используют для:", options: ["Неформального приветствия", "Формального приветствия", "Прощания", "Благодарности"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Как попрощаться неформально?", options: ["Сау бол", "Сау болыңыз", "Сәлем", "Сәлеметсіз бе"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "С учителем нужно:", options: ["Формальные формы (Сәлеметсіз бе, Сау болыңыз)", "Только Сәлем", "Только Сау бол", "Без приветствия"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Сәлеметсіз бе — это:", options: ["Формальное приветствие", "Неформальное прощание", "Спасибо", "Пожалуйста"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Сау бол — это:", options: ["Неформальное прощание", "Формальное приветствие", "Формальное прощание", "Неформальное приветствие"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Какая фраза формальная?", options: ["Сау болыңыз", "Сау бол", "Сәлем", "Нет"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Формальные формы используют с:", options: ["Учителями и старшими", "Только с друзьями", "Ни с кем", "Только на письме"], correctIndex: 0, points: 1),
                ]
            )
        case 6:
            return GeneratedLessonContent(
                title: "Первые слова: учёба",
                explanationSlides: [
                    "Полезные слова: мұғалім (учитель), сыныптасы (одноклассник). Послушайте, как они звучат.",
                    "Учителю — Сәлеметсіз бе. Однокласснику можно Сәлем.",
                    "Всё просто: учитель → формально. Одноклассник → неформально."
                ],
                examples: ["мұғалім — учитель", "сыныптасы — одноклассник", "Учителю: Сәлеметсіз бе", "Однокласснику: Сәлем"],
                quiz: [
                    GeneratedQuizItem(question: "мұғалім  -  [Muğalim]", options: ["Слышите? Это «учитель» по-казахски."], correctIndex: 0, points: 0, type: "listening", audioText: "мұғалім"),
                    GeneratedQuizItem(question: "Что значит мұғалім?", options: ["Учитель", "Ученик", "Школа", "Книга"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "С кем говорят Сәлеметсіз бе?", options: ["С учителем", "Только с другом", "Ни с кем", "Только на письме"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "сыныптасы значит:", options: ["Одноклассник", "Учитель", "Класс", "Урок"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Учителю говорят:", options: ["Сәлеметсіз бе", "Сәлем", "Сау бол", "Сау болыңыз"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Однокласснику можно сказать:", options: ["Сәлем", "Только Сәлеметсіз бе", "Ничего", "Сау болыңыз"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "мұғалім — это слово:", options: ["Казахское для «учитель»", "Казахское для «ученик»", "Приветствие", "Прощание"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "сыныптасы — это:", options: ["Одноклассник", "Учитель", "Школа", "Книга"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Какое слово значит «учитель»?", options: ["мұғалім", "сыныптасы", "Сәлем", "Сау бол"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Какое слово значит «одноклассник»?", options: ["сыныптасы", "мұғалім", "оқушы", "Сәлеметсіз бе"], correctIndex: 0, points: 1),
                ]
            )
        case 7:
            return GeneratedLessonContent(
                title: "Тест. Блок 2",
                explanationSlides: [
                    "Этот тест проверяет блок 2:\n\nприветствия и прощания,\n\nсловарь (мұғалім, сыныптасы),\n\nкогда Сәлем и Сәлеметсіз бе."
                ],
                examples: [],
                quiz: [
                    GeneratedQuizItem(question: "Правильное формальное прощание:", options: ["Сау болыңыз", "Сәлем", "Сау бол", "Сәлеметсіз бе"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Сәлеметсіз бе говорят:", options: ["Учителю", "Близкому другу", "Никому", "Только утром"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "мұғалім — это:", options: ["Учитель", "Одноклассник", "Ученик", "Школа"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "сыныптасы значит:", options: ["Одноклассник", "Учитель", "Школа", "Книга"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Неформальное приветствие:", options: ["Сәлем", "Сәлеметсіз бе", "Сау болыңыз", "Нет"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Формальное приветствие:", options: ["Сәлеметсіз бе", "Сәлем", "Сау бол", "Сау болыңыз"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "С учителем используют:", options: ["Сәлеметсіз бе (привет), Сау болыңыз (прощание)", "Только Сәлем", "Только Сау бол", "Без приветствия"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Сау бол — это:", options: ["Неформальное прощание", "Формальное приветствие", "Учитель", "Одноклассник"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Кто из перечисленного — человек (словарь)?", options: ["мұғалім", "Сәлем", "Сау бол", "Сәлеметсіз бе"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Однокласснику говорят:", options: ["Сәлем", "Только Сәлеметсіз бе", "Только Сау болыңыз", "Ничего"], correctIndex: 0, points: 1),
                ]
            )
        case 8:
            return GeneratedLessonContent(
                title: "Я и ты + словарь",
                explanationSlides: [
                    "мен = я, сен = ты (неформально). С ними используются личные окончания: «я — ...», «ты — ...».",
                    "Новое слово: оқушы (ученик). Послушайте. Позже: Мен оқушы + мын = Мен оқушымын (я ученик).",
                    "Как в блоке 1 с гласными: каждый шаг опирается на предыдущий. От приветствий к полным предложениям."
                ],
                examples: ["мен — я", "сен — ты (неформально)", "оқушы — ученик"],
                quiz: [
                    GeneratedQuizItem(question: "оқушы  -  [Oqushy]", options: ["Слышите? Это «ученик» по-казахски."], correctIndex: 0, points: 0, type: "listening", audioText: "оқушы"),
                    GeneratedQuizItem(question: "Что значит мен?", options: ["Я", "Ты", "Он", "Мы"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "сен — это:", options: ["Ты (неформально)", "Я", "Учитель", "Ученик"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "оқушы значит:", options: ["Ученик", "Учитель", "Школа", "Книга"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "мен — местоимение для:", options: ["Я", "Ты", "Он", "Они"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "сен — местоимение для:", options: ["Ты (неформально)", "Я", "Мы", "Она"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Личные окончания добавляют, чтобы сказать:", options: ["Я — ... / Ты — ...", "Привет / Пока", "Спасибо", "Ничего"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "оқушы — это:", options: ["Ученик", "Учитель", "Одноклассник", "Школа"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Какое слово значит «я»?", options: ["мен", "сен", "оқушы", "мұғалім"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Мен оқушымын значит (в следующем уроке):", options: ["Я ученик", "Ты ученик", "Я учитель", "Ты учитель"], correctIndex: 0, points: 1),
                ]
            )
        case 9:
            return GeneratedLessonContent(
                title: "Личные окончания",
                explanationSlides: [
                    "С мен (я): -мың, -мін, -бын, -бін, -пын, -пін. С сен (ты): -сың, -сің.",
                    "Окончания добавляются к существительным, профессиям, прилагательным. мұғалім + мін = Мен мұғаліммін. оқушы + сың = Сен оқушысың.",
                    "Как сингармонизм: окончание зависит от гласной. Передняя гласная → -мін, -сің. Задняя → -мың, -сың."
                ],
                examples: ["Мен мұғаліммін — я учитель", "Сен оқушысың — ты ученик", "Окончания: -мың/-мін (я), -сың/-сің (ты)"],
                quiz: [
                    GeneratedQuizItem(question: "Мен мұғаліммін  -  [Men muğalimmin]", options: ["Слышите? «Я учитель»."], correctIndex: 0, points: 0, type: "listening", audioText: "Мен мұғаліммін"),
                    GeneratedQuizItem(question: "Какое окончание с сен (ты)?", options: ["-сың / -сің", "-мың / -мін", "-бын", "-пын"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Мен мұғаліммін значит:", options: ["Я учитель", "Ты учитель", "Он учитель", "Мы учителя"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Личные окончания добавляют к:", options: ["Именам, профессиям, существительным", "Только глаголам", "Только числам", "Ни к чему"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Какое окончание с мен (я)?", options: ["-мың / -мін (и -бын, -пін и т.д.)", "Только -сың / -сің", "Без окончания", "Только -бын"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Сен оқушысың значит:", options: ["Ты ученик", "Я ученик", "Он ученик", "Мы ученики"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "мұғалім + мін (с мен) =", options: ["Мен мұғаліммін", "Сен мұғалімсің", "Мен оқушымын", "Сен оқушысың"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Окончания -сың, -сің с:", options: ["сен (ты)", "мен (я)", "оқушы", "мұғалім"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "«Я учитель» по-казахски:", options: ["Мен мұғаліммін", "Сен мұғалімсің", "Мен оқушымын", "Сен оқушысың"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "«Ты ученик» по-казахски:", options: ["Сен оқушысың", "Мен оқушымын", "Мен мұғаліммін", "Сен мұғалімсің"], correctIndex: 0, points: 1),
                ]
            )
        case 10:
            return GeneratedLessonContent(
                title: "Употребление: Мен мұғаліммін, сен оқушысың",
                explanationSlides: [
                    "Вместе: Мен мұғаліммін (я учитель), Сен оқушысың (ты ученик).",
                    "Окончание зависит от последней гласной: после задних -мың, -сың; после передних -мін, -сің.",
                    "Потренируйтесь произносить оба. Теперь у вас основа: я есть / ты есть + профессия или существительное."
                ],
                examples: ["Мен мұғаліммін — я учитель", "Сен оқушысың — ты ученик"],
                quiz: [
                    GeneratedQuizItem(question: "Сен оқушысың  -  [Sen oqushysyñ]", options: ["Слышите? «Ты ученик»."], correctIndex: 0, points: 0, type: "listening", audioText: "Сен оқушысың"),
                    GeneratedQuizItem(question: "Сен оқушысың значит:", options: ["Ты ученик", "Я ученик", "Он ученик", "Мы ученики"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Как сказать «я учитель» по-казахски?", options: ["Мен мұғаліммін", "Сен мұғалімсің", "Мен оқушымын", "Сен оқушысың"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Мен мұғаліммін — это:", options: ["Я учитель", "Ты учитель", "Я ученик", "Ты ученик"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Сен оқушысың — это:", options: ["Ты ученик", "Я ученик", "Я учитель", "Ты учитель"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Окончание -мін в мұғаліммін с:", options: ["мен (я)", "сен (ты)", "оқушы", "сыныптасы"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Окончание -сың в оқушысың с:", options: ["сен (ты)", "мен (я)", "мұғалім", "только оқушы"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Какое предложение значит «Ты ученик»?", options: ["Сен оқушысың", "Мен оқушымын", "Мен мұғаліммін", "Сен мұғалімсің"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "мұғаліммін — окончание для:", options: ["Я (мен)", "Ты (сен)", "Он", "Мы"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "оқушысың — окончание для:", options: ["Ты (сен)", "Я (мен)", "Учитель", "Ученик"], correctIndex: 0, points: 1),
                ]
            )
        case 11:
            return GeneratedLessonContent(
                title: "Тест. Блок 3",
                explanationSlides: [
                    "Этот тест проверяет блок 3:\n\nмен и сен,\n\nоқушы,\n\nличные окончания (-мың/-мін, -сың/-сің),\n\nпредложения Мен мұғаліммін, Сен оқушысың."
                ],
                examples: [],
                quiz: [
                    GeneratedQuizItem(question: "Мен мұғаліммін значит:", options: ["Я учитель", "Ты учитель", "Я ученик", "Ты ученик"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "С каким местоимением окончание -сың/-сің?", options: ["сен (ты)", "мен (я)", "оқушы", "мұғалім"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Правильно по-казахски «Ты ученик»:", options: ["Сен оқушысың", "Мен оқушымын", "Сен мұғалімсің", "Мен мұғаліммін"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "мен значит:", options: ["Я", "Ты", "Ученик", "Учитель"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "сен значит:", options: ["Ты (неформально)", "Я", "Он", "Мы"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "оқушы значит:", options: ["Ученик", "Учитель", "Одноклассник", "Школа"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Какое окончание с мен?", options: ["-мың / -мін", "-сың / -сің", "Без окончания", "Только -сың"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Сен оқушысың по-русски:", options: ["Ты ученик", "Я ученик", "Я учитель", "Ты учитель"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Мен оқушымын значит:", options: ["Я ученик", "Ты ученик", "Я учитель", "Ты учитель"], correctIndex: 0, points: 1),
                    GeneratedQuizItem(question: "Личные окончания присоединяются к:", options: ["Существительным, профессиям (напр. мұғалім, оқушы)", "Только глаголам", "Только приветствиям", "Ни к чему"], correctIndex: 0, points: 1),
                ]
            )
        default:
            return bundledEnglish(for: 1)
        }
    }
}

struct GeneratedQuizItem: Codable {
    var question: String
    var options: [String]
    var correctIndex: Int
    var points: Int? = nil
    /// Question type: multiple_choice (default), listening (play audio then choose), match (e.g. connect by sound).
    var type: String? = nil
    /// For listening questions: the Kazakh text to speak via Azure TTS.
    var audioText: String? = nil

    enum CodingKeys: String, CodingKey {
        case question, options, points, audioText
        case correctIndex = "correct_index"
        case type = "question_type"
    }

    init(question: String, options: [String], correctIndex: Int, points: Int? = nil, type: String? = nil, audioText: String? = nil) {
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.points = points
        self.type = type
        self.audioText = audioText
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        question = try c.decode(String.self, forKey: .question)
        options = try c.decode([String].self, forKey: .options)
        correctIndex = try c.decode(Int.self, forKey: .correctIndex)
        points = try c.decodeIfPresent(Int.self, forKey: .points)
        type = try c.decodeIfPresent(String.self, forKey: .type)
        audioText = try c.decodeIfPresent(String.self, forKey: .audioText)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(question, forKey: .question)
        try c.encode(options, forKey: .options)
        try c.encode(correctIndex, forKey: .correctIndex)
        try c.encodeIfPresent(points, forKey: .points)
        try c.encodeIfPresent(type, forKey: .type)
        try c.encodeIfPresent(audioText, forKey: .audioText)
    }
}
