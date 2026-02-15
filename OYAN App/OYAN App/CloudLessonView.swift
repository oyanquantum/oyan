//
//  CloudLessonView.swift
//  OYAN App
//
//  One lesson or unit test from the cloud path. Same design as LanguageTestView: eagle, bubble, content, quiz, correctness %.
//

import SwiftUI

private let lessonContentCacheKeyPrefix = "oyan_lesson_content_v8_"

struct CloudLessonView: View {
    let cloudIndex: Int
    let selectedLanguage: Language
    /// Called when user completes the lesson (taps "Back to lessons") so HomeView can refresh lock state.
    var onComplete: (() -> Void)? = nil

    @State private var content: GeneratedLessonContent?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var phase: LessonPhase = .explanation
    @State private var currentSlideIndex = 0
    @State private var currentQuizIndex = 0
    @State private var quizCorrectCount = 0
    @State private var quizPointsEarned = 0
    @State private var selectedAnswer: String?
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var showResults = false
    @State private var navigateBack = false
    @State private var displayedOptions: [String] = []
    @State private var displayedCorrectAnswer: String = ""
    @State private var connectBySoundSlots: [String?] = [nil, nil, nil, nil]
    @Environment(\.dismiss) private var dismiss

    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#f9a63c")

    private var node: CloudNode? { CourseStructure.node(for: cloudIndex) }

    enum LessonPhase {
        case explanation
        case quiz
        case results
    }

    private var explanationSlides: [String] {
        guard let c = content else { return [] }
        if c.explanationSlides.isEmpty { return [c.title] }
        return c.explanationSlides
    }

    private var currentQuizItem: GeneratedQuizItem? {
        guard let c = content, currentQuizIndex < c.quiz.count else { return nil }
        return c.quiz[currentQuizIndex]
    }

    private var totalQuizCount: Int { content?.quiz.count ?? 0 }
    private var totalPossiblePoints: Int {
        guard let c = content else { return totalQuizCount }
        return c.quiz.reduce(0) { sum, item in sum + (item.points ?? 1) }
    }
    private var correctPercentage: Int {
        let total = totalPossiblePoints
        guard total > 0 else { return 0 }
        return Int(round(Double(quizPointsEarned) / Double(total) * 100))
    }

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let content = content, let node = node {
                mainFlow(content: content, node: node)
            } else {
                errorView
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
        .task { await loadContent() }
        .onChange(of: showResults) { _, show in
            if show && totalQuizCount > 0 {
                let estimatedSeconds = 5 * 60 + totalQuizCount * 30
                addStudyTimeSeconds(min(estimatedSeconds, 7 * 60))
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            Text(selectedLanguage == .english ? "Loading lesson…" : "Загрузка урока…")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor.ignoresSafeArea())
    }

    private func mainFlow(content: GeneratedLessonContent, node: CloudNode) -> some View {
        ZStack {
            if phase == .explanation {
                explanationPhase
            } else if phase == .quiz, let item = currentQuizItem {
                quizPhase(item: item)
            } else if phase == .results {
                resultsPhase
            }
        }
    }

    private var explanationPhase: some View {
        let boxFillColor = Color(hex: "#fefdf5")
        let accentOrange = Color(hex: "#d26b08")
        let lessonLabel = (node?.isTest == true)
            ? (selectedLanguage == .english ? "Unit \(node?.unitIndex ?? 1) Test" : "Блок \(node?.unitIndex ?? 1) Тест")
            : (selectedLanguage == .english ? "Lesson \(node?.id ?? 1)" : "Урок \(node?.id ?? 1)")
        return ZStack(alignment: .topLeading) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Box - independent overlay, same position and size, scrollable when content overflows
            let currentSlide = explanationSlides.indices.contains(currentSlideIndex) ? explanationSlides[currentSlideIndex] : ""
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        if (currentSlide.contains("synharmonism") || currentSlide.contains("сингармонизм")) && (currentSlide.contains("Kazakh is a Turkic") || currentSlide.contains("Казахский — тюркский")) {
                            (Text(currentSlide.hasPrefix("Kazakh") ? "Kazakh is a Turkic language spoken in Kazakhstan. One of its key features is " : "Казахский — тюркский язык, на котором говорят в Казахстане. Одна из главных черт — ")
                                .foregroundColor(.black)) +
                            (Text(currentSlide.hasPrefix("Kazakh") ? "synharmonism: vowels in a word 'agree' with each other - like notes in a melody." : "сингармонизм: гласные в слове «согласуются» друг с другом, как ноты в мелодии.")
                                .foregroundColor(Color(hex: "#fea813")))
                        } else if currentSlide.contains("Think of language as music") || currentSlide.contains("Представьте язык как музыку") {
                            let highlight = Color(hex: "#d26b08")
                            (Text(currentSlide.hasPrefix("Think") ? "Think of " : "Представьте ")
                                .foregroundColor(.black)) +
                            (Text(currentSlide.hasPrefix("Think") ? "language as music" : "язык как музыку")
                                .foregroundColor(highlight)) +
                            (Text(currentSlide.hasPrefix("Think") ? ": soft vowels go together, hard vowels go together. This makes words sound " : ": мягкие гласные с мягкими, твёрдые с твёрдыми. Так слова звучат ")
                                .foregroundColor(.black)) +
                            (Text(currentSlide.hasPrefix("Think") ? "smooth and consistent." : "ровно и последовательно.")
                                .foregroundColor(highlight))
                        } else if currentSlide.contains("Kazakh has vowels and consonants") || currentSlide.contains("В казахском есть гласные и согласные") {
                            let highlight = Color(hex: "#d26b08")
                            (Text(currentSlide.hasPrefix("Kazakh") ? "Kazakh has vowels and consonants. Vowels can be " : "В казахском есть гласные и согласные. Гласные бывают ")
                                .foregroundColor(.black)) +
                            (Text(currentSlide.hasPrefix("Kazakh") ? "hard" : "твёрдыми")
                                .foregroundColor(highlight)) +
                            (Text(currentSlide.hasPrefix("Kazakh") ? " (back) or " : " (задние) и ")
                                .foregroundColor(.black)) +
                            (Text(currentSlide.hasPrefix("Kazakh") ? "soft" : "мягкими")
                                .foregroundColor(highlight)) +
                            (Text(currentSlide.hasPrefix("Kazakh") ? " (front)." : " (передние).")
                                .foregroundColor(.black))
                        } else if (currentSlide.contains("Hard vowels: А") || currentSlide.contains("Твёрдые гласные: А")) && (currentSlide.contains("Universal:") || currentSlide.contains("Универсальные:")) {
                            let highlight = Color(hex: "#d26b08")
                            let isEn = currentSlide.hasPrefix("Hard")
                            (Text(isEn ? "Hard vowels: " : "Твёрдые гласные: ")
                                .foregroundColor(highlight)) +
                            (Text(isEn ? "А  [A],  О  [O],  У  [W],  Ұ [ U],  Ы  [I] \n\n" : "А  [A],  О  [O],  У  [W],  Ұ [ U],  Ы  [I] \n\n")
                                .foregroundColor(.black)) +
                            (Text(isEn ? "Soft vowels: " : "Мягкие гласные: ")
                                .foregroundColor(highlight)) +
                            (Text(isEn ? "Ә  [Ä],  Е  [E],  І  [I],  Ө  [Ö],  Ү  [Ü],  Э  [É]\n\n" : "Ә  [Ä],  Е  [E],  І  [I],  Ө  [Ö],  Ү  [Ü],  Э  [É]\n\n")
                                .foregroundColor(.black)) +
                            (Text(isEn ? "Universal: " : "Универсальные: ")
                                .foregroundColor(highlight)) +
                            (Text(isEn ? "И  [I],  У  [W] \n\n" : "И  [I],  У  [W] \n\n")
                                .foregroundColor(.black)) +
                            (Text(isEn ? "The type of vowel in a word determines which endings we use later." : "Тип гласной в слове определяет, какие окончания мы будем использовать.")
                                .foregroundColor(.black))
                        } else if currentSlide.contains("First law: a soft vowel") || currentSlide.contains("Первый закон: мягкая гласная") {
                            let highlight = Color(hex: "#d26b08")
                            let isEn = currentSlide.hasPrefix("First")
                            (Text(isEn ? "First law: " : "Первый закон: ")
                                .foregroundColor(highlight)) +
                            (Text(isEn ? "a " : " ")
                                .foregroundColor(.black)) +
                            (Text(isEn ? "soft vowel " : "мягкая гласная ")
                                .foregroundColor(highlight)) +
                            (Text(isEn ? "creates a " : "создаёт ")
                                .foregroundColor(.black)) +
                            (Text(isEn ? "soft syllable" : "мягкий слог")
                                .foregroundColor(highlight)) +
                            (Text(isEn ? "; a " : ", ")
                                .foregroundColor(.black)) +
                            (Text(isEn ? "hard vowel " : "твёрдая")
                                .foregroundColor(highlight)) +
                            (Text(isEn ? "creates a " : " — ")
                                .foregroundColor(.black)) +
                            (Text(isEn ? "hard syllable" : "твёрдый")
                                .foregroundColor(highlight)) +
                            (Text(isEn ? ".\n\nSo one word usually has only hard vowels or only soft vowels." : ".\n\nПоэтому в одном слове обычно только твёрдые или только мягкие гласные.")
                                .foregroundColor(.black))
                        } else if currentSlide.contains("Practice these words:") && currentSlide.contains("Бас - [bas]") || currentSlide.contains("Потренируйтесь:") && currentSlide.contains("Бас - [bas]") {
                            let highlight = Color(hex: "#d26b08")
                            let isEn = currentSlide.hasPrefix("Practice")
                            (Text(isEn ? "Practice these words:\n\n" : "Потренируйтесь:\n\n")
                                .foregroundColor(.black)) +
                            (Text("Бас - [bas]\n")
                                .foregroundColor(highlight)) +
                            (Text("Қыз - [qiz]\n")
                                .foregroundColor(highlight)) +
                            (Text("Кет - [ket]\n")
                                .foregroundColor(highlight)) +
                            (Text("Көз - [köz]\n\n")
                                .foregroundColor(highlight)) +
                            (Text(isEn ? "Try to determine which of them are soft and which are hard." : "Постарайтесь определить, какие из них мягкие, а какие твёрдые.")
                                .foregroundColor(.black))
                        } else if currentSlide.contains("Don't worry!") && currentSlide.contains("hear the difference") {
                            let highlight = Color(hex: "#d26b08")
                            (Text("Don't worry! In this lesson you don't need to understand the meaning, you just need to ")
                                .foregroundColor(.black)) +
                            (Text("hear the difference between hard and soft sounds.")
                                .foregroundColor(highlight))
                        } else if currentSlide.contains("**") {
                            HighlightedTextView(text: currentSlide, highlightColor: Color(hex: "#d26b08"))
                        } else {
                            Text(currentSlide)
                                .foregroundColor(.black)
                        }
                    }
                    .font(.system(size: 26))
                    .fixedSize(horizontal: false, vertical: true)
                    if currentSlideIndex == 0, let c = content, !c.examples.isEmpty {
                        Spacer().frame(height: 28)
                        let isLesson2Info1 = (currentSlide.contains("Kazakh has vowels and consonants") || currentSlide.contains("В казахском есть гласные и согласные"))
                        ForEach(c.examples, id: \.self) { ex in
                            Text(ex)
                                .font(.system(size: 26))
                                .foregroundColor(isLesson2Info1 ? Color(hex: "#d26b08") : .primary)
                        }
                    }
                    if cloudIndex == 1 && currentSlideIndex == 2 {
                        Spacer().frame(height: 24)
                        let soundButtonColor = Color(hex: "#fea813")
                        Text("Hard:")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.black)
                        HStack(alignment: .center, spacing: 14) {
                            Button {
                                Task { await KazakhAudioButton.play(text: "Ды") }
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundColor(soundButtonColor)
                            }
                            .buttonStyle(.plain)
                            Text("Ды")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#e0dcc8"), lineWidth: 1))
                                )
                            Text(" - Dı")
                                .font(.system(size: 22))
                                .foregroundColor(.secondary)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                        HStack(alignment: .center, spacing: 14) {
                            Button {
                                Task { await KazakhAudioButton.play(text: "Ма") }
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundColor(soundButtonColor)
                            }
                            .buttonStyle(.plain)
                            Text("Ма")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#e0dcc8"), lineWidth: 1))
                                )
                            Text(" - Ma")
                                .font(.system(size: 22))
                                .foregroundColor(.secondary)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                        Spacer().frame(height: 12)
                        Text("Soft:")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.black)
                        HStack(alignment: .center, spacing: 14) {
                            Button {
                                Task { await KazakhAudioButton.play(text: "Ті") }
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundColor(soundButtonColor)
                            }
                            .buttonStyle(.plain)
                            Text("Ті")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#e0dcc8"), lineWidth: 1))
                                )
                            Text(" - Ti")
                                .font(.system(size: 22))
                                .foregroundColor(.secondary)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                        HStack(alignment: .center, spacing: 14) {
                            Button {
                                Task { await KazakhAudioButton.play(text: "Мә") }
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundColor(soundButtonColor)
                            }
                            .buttonStyle(.plain)
                            Text("Мә")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#e0dcc8"), lineWidth: 1))
                                )
                            Text(" - Mä")
                                .font(.system(size: 22))
                                .foregroundColor(.secondary)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(20)
            }
            .scrollIndicators(.visible)
            .tint(Color(hex: "#fea813"))
            .frame(maxWidth: .infinity, maxHeight: 420, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(boxFillColor)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, -80)
            .offset(y: currentSlideIndex == 0 ? 200 : 150)
            .ignoresSafeArea(edges: .bottom)

            // Titles - independent overlay
            VStack(alignment: .leading, spacing: 6) {
                Text(lessonLabel)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "#fea813"))
                    .lineLimit(1)
                Text(content?.title ?? "")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                Rectangle()
                    .fill(Color(hex: "#fea813"))
                    .frame(height: 2)
                    .frame(width: 180, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 100)
            .allowsHitTesting(false)
            .opacity(currentSlideIndex == 0 ? 1 : 0)

            // Eagle - independent overlay, its own size and position (only on first slide)
            Image("eagle_speech")
                .resizable()
                .scaledToFit()
                .frame(width: 320, height: 320)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, -100)
                .padding(.trailing, -40)
                .allowsHitTesting(false)
                .opacity(currentSlideIndex == 0 ? 1 : 0)

            // Orange line - on info 2, L1 info 3, and slide 2+ (between eagle and box)
            let isInfo2OrL1Info3 = currentSlideIndex == 1 || (cloudIndex == 1 && currentSlideIndex == 2)
            let showEagleBook = currentSlideIndex >= 2 && !(cloudIndex == 1 && currentSlideIndex == 2)
            Rectangle()
                .fill(Color(hex: "#fea813"))
                .frame(height: 2)
                .frame(width: 180, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 140)
                .allowsHitTesting(false)
                .opacity((isInfo2OrL1Info3 || showEagleBook) ? 1 : 0)

            // Eagle - above the box on info 2 and L1 info 3
            // L1 info 2: eagle_music (smaller). L1 info 3: eagle_teaching. L2: eagle_book. L3+: eagle_book
            let isLesson1Info2 = cloudIndex == 1 && currentSlideIndex == 1
            let isLesson1Info3 = cloudIndex == 1 && currentSlideIndex == 2
            let isLesson2Info2 = cloudIndex == 2 && currentSlideIndex == 1
            let isInfo2Template = cloudIndex >= 3 && currentSlideIndex == 1
            let eagleName = isLesson1Info2 ? "eagle_music" : (isLesson1Info3 ? "eagle_teaching" : "eagle_book")
            let eagleSize: CGFloat = isLesson1Info2 ? 260 : (isLesson1Info3 ? 384 : 320)
            let eagleOffsetX: CGFloat = isLesson1Info2 ? 82 : (isLesson1Info3 ? 70 : (isLesson2Info2 ? 56 : (isInfo2Template ? 80 : 0)))
            let eagleOffsetY: CGFloat = isLesson1Info2 ? 76 : (isLesson1Info3 ? 8 : (isLesson2Info2 ? 36 : (isInfo2Template ? 38 : 0)))
            Image(eagleName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: eagleSize, height: eagleSize)
                .frame(maxWidth: .infinity)
                .padding(.top, -20)
                .padding(.bottom, 8)
                .offset(y: isInfo2OrL1Info3 ? -100 : -500)
                .offset(x: eagleOffsetX, y: eagleOffsetY)
                .allowsHitTesting(false)
                .opacity(isInfo2OrL1Info3 ? 1 : 0)

            // Eagle with book - for explanation slides that don't already have an eagle (slide 2+ on most lessons)
            // Same position and orange line as slide 1 (eagle_book / isInfo2Template)
            Image("eagle_book")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 320, height: 320)
                .frame(maxWidth: .infinity)
                .padding(.top, -20)
                .padding(.bottom, 8)
                .offset(y: showEagleBook ? -100 : -500)
                .offset(x: 80, y: 38)
                .allowsHitTesting(false)
                .opacity(showEagleBook ? 1 : 0)

            // Button - overlay so it stays on top and tappable
            VStack {
                Spacer()
                Button {
                    if currentSlideIndex + 1 < explanationSlides.count {
                        currentSlideIndex += 1
                    } else {
                        phase = totalQuizCount > 0 ? .quiz : .results
                        if totalQuizCount == 0 { showResults = true }
                    }
                } label: {
                    Text(selectedLanguage == .english ? "Continue" : "Продолжить")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 0)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#fea813"))
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func quizPhase(item: GeneratedQuizItem) -> some View {
        let options = displayedOptions.isEmpty ? item.options : displayedOptions
        let correctAnswer = displayedCorrectAnswer.isEmpty ? (item.options.indices.contains(item.correctIndex) ? item.options[item.correctIndex] : (item.options.first ?? "")) : displayedCorrectAnswer
        let isMektP = item.question.contains("Мект_п") || item.question.contains("Б_ркіт") || item.question.contains("Кіт_п")
        let isSyllableSoftQuestion = item.question.contains("Which syllable sounds soft?") || item.question.contains("Какий слог звучит мягко?")
        let isConnectBySound = (item.type == "match") || item.question.contains("Connect by sound") || item.question.contains("Соедини по звуку")
        let isListening = (item.type == "listening") || (item.audioText != nil)
        let isListeningIntro = item.question.contains("Достық") || (isListening && options.count == 1)
        return VStack(spacing: 0) {
            Spacer().frame(height: 32)
            ZStack {
                backgroundColor.ignoresSafeArea()
                VStack(spacing: isListeningIntro ? 8 : 20) {
                    Spacer().frame(height: isListeningIntro ? 130 : 100)
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(buttonColor)
                            .shadow(color: buttonColor.opacity(0.3), radius: 10, x: 0, y: 4)
                        Group {
                            if isMektP, item.question.contains("\n") {
                                let parts = item.question.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                                VStack(spacing: 6) {
                                    Text(String(parts.first ?? ""))
                                    Text(parts.count > 1 ? String(parts[1]) : "")
                                }
                            } else {
                                Text(item.question)
                            }
                        }
                            .font(isListeningIntro ? .title : (isMektP || isSyllableSoftQuestion || isConnectBySound ? .title2 : .title3))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                    }
                    .frame(maxWidth: (isMektP || isSyllableSoftQuestion || isConnectBySound) ? 336 : 320, maxHeight: (isMektP || isSyllableSoftQuestion || isConnectBySound) ? 180 : 140)
                    .padding(.vertical, isListeningIntro ? 4 : 10)

                    // Connect by sound: two word slots (soft + hard), user taps 4 syllables in order
                    if isConnectBySound {
                        let slotBoxCorrect = showFeedback && isCorrect
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                ForEach(0..<2, id: \.self) { i in
                                    ConnectSlotView(
                                        text: connectBySoundSlots[i],
                                        accentColor: slotBoxCorrect ? Color.green : buttonColor,
                                        onTap: {
                                            if !showFeedback { connectBySoundSlots[i] = nil }
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(slotBoxCorrect ? Color.green.opacity(0.15) : Color.white)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(slotBoxCorrect ? Color.green : buttonColor.opacity(0.35), lineWidth: 2))
                            )
                            HStack(spacing: 12) {
                                ForEach(2..<4, id: \.self) { i in
                                    ConnectSlotView(
                                        text: connectBySoundSlots[i],
                                        accentColor: slotBoxCorrect ? Color.green : buttonColor,
                                        onTap: {
                                            if !showFeedback { connectBySoundSlots[i] = nil }
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(slotBoxCorrect ? Color.green.opacity(0.15) : Color.white)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(slotBoxCorrect ? Color.green : buttonColor.opacity(0.35), lineWidth: 2))
                            )
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 12)

                        HStack(spacing: 12) {
                            ForEach(options, id: \.self) { syllable in
                                let used = connectBySoundSlots.contains(syllable)
                                Button {
                                    if !showFeedback && !used {
                                        if let idx = connectBySoundSlots.firstIndex(where: { $0 == nil }) {
                                            connectBySoundSlots[idx] = syllable
                                            Task { await KazakhAudioButton.play(text: syllable) }
                                        }
                                    }
                                } label: {
                                    Text(syllable)
                                        .font(.title2)
                                        .foregroundColor(used ? .secondary : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(Color.white)
                                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(used ? Color.gray.opacity(0.3) : buttonColor.opacity(0.35), lineWidth: 2))
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(used)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 12)
                    }

                    if !isConnectBySound {
                        VStack(spacing: 12) {
                            ForEach(options, id: \.self) { option in
                                let syllableToPlay: String = isSyllableSoftQuestion ? (option.split(separator: " ", maxSplits: 1).first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? option) : option
                                HStack(alignment: .center, spacing: 10) {
                                    if isSyllableSoftQuestion {
                                        Button {
                                            Task { await KazakhAudioButton.play(text: syllableToPlay) }
                                        } label: {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .font(.title3)
                                                .foregroundColor(buttonColor)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    AnswerButton(
                                        text: option,
                                        isSelected: selectedAnswer == option,
                                        accentColor: buttonColor,
                                        showAsCorrect: showFeedback && option == correctAnswer,
                                        showAsWrong: showFeedback && !isCorrect && option == selectedAnswer,
                                        isLarge: isListeningIntro,
                                        isSlightlyLarger: isMektP || isSyllableSoftQuestion
                                    ) {
                                        if !showFeedback && !isListeningIntro { selectedAnswer = option }
                                    }
                                }
                            }
                        }
                        .allowsHitTesting(!isListeningIntro)
                        .padding(.horizontal, isListeningIntro ? 24 : 30)
                        .padding(.top, isListeningIntro ? 8 : 20)
                    }

                    ZStack(alignment: .center) {
                        if !isListeningIntro {
                            let connectFilled = isConnectBySound && connectBySoundSlots.allSatisfy { $0 != nil }
                            let canCheck = isConnectBySound ? connectFilled : (selectedAnswer != nil)
                            HStack(spacing: 12) {
                                Button {
                                    if !showFeedback {
                                        isCorrect = false
                                        if isConnectBySound { connectBySoundSlots = [nil, nil, nil, nil] }
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showFeedback = true }
                                    }
                                } label: {
                                    Text(selectedLanguage == .english ? "Not sure" : "Не уверен")
                                        .font((isMektP || isSyllableSoftQuestion || isConnectBySound) ? .title2 : .title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, (isMektP || isSyllableSoftQuestion || isConnectBySound) ? 18 : 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(showFeedback ? buttonColor.opacity(0.45) : buttonColor)
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(showFeedback)

                                Button {
                                    if canCheck && !showFeedback {
                                        if isConnectBySound {
                                            let filled = connectBySoundSlots.compactMap { $0 }
                                            let word1 = (filled.count >= 2) ? (filled[0] + filled[1]) : ""
                                            let word2 = (filled.count >= 4) ? (filled[2] + filled[3]) : ""
                                            let opts = item.options
                                            if opts.contains("Ал") {
                                                isCorrect = (word1 == "Алмұрт" && word2 == "Сәбіз") || (word1 == "Сәбіз" && word2 == "Алмұрт")
                                            } else if opts.contains("Тү") {
                                                isCorrect = (word1 == "Мысық" && word2 == "Түйе") || (word1 == "Түйе" && word2 == "Мысық")
                                            } else if opts.contains("Жү") {
                                                isCorrect = (word1 == "Жүрек" && word2 == "Мысық") || (word1 == "Мысық" && word2 == "Жүрек")
                                            } else {
                                                isCorrect = false
                                            }
                                        } else {
                                            isCorrect = (selectedAnswer == correctAnswer)
                                        }
                                        if isCorrect {
                                            quizCorrectCount += 1
                                            if let it = currentQuizItem {
                                                quizPointsEarned += (it.points ?? 1)
                                            }
                                        }
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showFeedback = true }
                                    }
                                } label: {
                                    Text(selectedLanguage == .english ? "Check" : "Проверить")
                                        .font((isMektP || isSyllableSoftQuestion || isConnectBySound) ? .title2 : .title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, (isMektP || isSyllableSoftQuestion || isConnectBySound) ? 18 : 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(!canCheck || showFeedback ? buttonColor.opacity(0.45) : buttonColor)
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(!canCheck || showFeedback)
                            }

                            if showFeedback {
                                Button {
                                    showFeedback = false
                                    selectedAnswer = nil
                                    if isConnectBySound { connectBySoundSlots = [nil, nil, nil, nil] }
                                    if currentQuizIndex + 1 >= totalQuizCount {
                                        phase = .results
                                        showResults = true
                                    } else {
                                        currentQuizIndex += 1
                                    }
                                } label: {
                                    Text(selectedLanguage == .english ? "Continue" : "Продолжить")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(buttonColor))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    Spacer()
                }
                .overlay(alignment: .bottom) {
                    if isListeningIntro {
                        VStack {
                            Spacer()
                            Button {
                                showFeedback = false
                                selectedAnswer = nil
                                if currentQuizIndex + 1 >= totalQuizCount {
                                    phase = .results
                                    showResults = true
                                } else {
                                    currentQuizIndex += 1
                                }
                            } label: {
                                Text(selectedLanguage == .english ? "Continue" : "Продолжить")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 0)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: "#fea813"))
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .onAppear {
                    if isConnectBySound {
                        connectBySoundSlots = [nil, nil, nil, nil]
                        displayedOptions = item.options
                        displayedCorrectAnswer = ""
                    } else {
                        let shuffled = item.options.shuffled()
                        displayedOptions = shuffled
                        displayedCorrectAnswer = item.options.indices.contains(item.correctIndex) ? item.options[item.correctIndex] : (item.options.first ?? "")
                    }
                }
                .id(currentQuizIndex)
                VStack {
                    HStack { Spacer()
                        ZStack(alignment: .topTrailing) {
                            // Only show bubble when it's feedback (not repeating the question from the orange box)
                            if showFeedback {
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text(isCorrect ? (selectedLanguage == .english ? "Great job!" : "Отлично!") : (selectedLanguage == .english ? "Oops, try again next time" : "Упс, в следующий раз получится"))
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .lineLimit(3)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        )
                                    Path { p in p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 20, y: 0)); p.addLine(to: CGPoint(x: 10, y: 15)); p.closeSubpath() }
                                        .fill(Color.white)
                                        .frame(width: 20, height: 15)
                                        .offset(x: -40, y: -2)
                                }
                                .padding(.trailing, 95)
                                .padding(.top, isCorrect ? -50 : -58)
                            }
                            if isListeningIntro || (isListening && !(item.audioText ?? "").isEmpty) {
                                let audioTextToPlay = isListeningIntro ? (item.audioText ?? "Достық") : (item.audioText ?? "")
                                let isReasonEagle = !showFeedback
                                let reasonEagleSize: CGFloat = 400
                                let feedbackEagleSize: CGFloat = (isMektP || isSyllableSoftQuestion || isConnectBySound) ? 336 : 320
                                ZStack(alignment: .topLeading) {
                                    Image(showFeedback ? (isCorrect ? "eagle_happy" : "eagle_sad") : "eagle_reason")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: isReasonEagle ? reasonEagleSize : feedbackEagleSize, maxHeight: isReasonEagle ? reasonEagleSize : feedbackEagleSize)
                                        .padding(.top, showFeedback ? (isCorrect ? -65 : -80) : -125)
                                        .padding(.trailing, isReasonEagle ? -40 : (showFeedback && isCorrect ? -15 : -15))
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                    KazakhAudioButton(text: audioTextToPlay)
                                        .allowsHitTesting(true)
                                        .padding(.leading, 48)
                                        .padding(.top, -20)
                                }
                            } else {
                                let isReasonEagle = !showFeedback
                                let reasonEagleSize: CGFloat = 400
                                let feedbackEagleSize: CGFloat = (isMektP || isSyllableSoftQuestion || isConnectBySound) ? 336 : 320
                                Image(showFeedback ? (isCorrect ? "eagle_happy" : "eagle_sad") : "eagle_reason")
                                    .renderingMode(.original)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: isReasonEagle ? reasonEagleSize : feedbackEagleSize, maxHeight: isReasonEagle ? reasonEagleSize : feedbackEagleSize)
                                    .padding(.top, showFeedback ? (isCorrect ? -65 : -80) : -125)
                                    .padding(.trailing, isReasonEagle ? -40 : (showFeedback && isCorrect ? -15 : -15))
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    Spacer()
                }

            }
        }
    }

    private var resultsPhase: some View {
        VStack(spacing: 0) {
            Spacer()
            // Bubble, eagle, percentage, button – moved up together
            VStack(spacing: 24) {
                // Bubble slot: fixed-height placeholder so eagle/button layout is independent; bubble drawn in overlay
                let bubbleAreaHeight: CGFloat = 80
                Color.clear
                    .frame(height: bubbleAreaHeight)
                    .overlay(alignment: .top) {
                        VStack(spacing: 0) {
                            Text(selectedLanguage == .english ? "Lesson complete! Here is your score." : "Урок завершён! Ваш результат.")
                                .font(.headline)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                            Path { p in p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 20, y: 0)); p.addLine(to: CGPoint(x: 10, y: 15)); p.closeSubpath() }
                                .fill(Color.white)
                                .frame(width: 20, height: 15)
                                .offset(y: -2)
                        }
                        .padding(.bottom, 8)
                        .offset(y: 320) // bubble only – move this to shift bubble without affecting anything else
                    }

                // Eagle slot: fixed-height placeholder so button/percentage layout is independent; eagle drawn in overlay
                let eagleAreaHeight = UIScreen.main.bounds.height * 0.53
                Color.clear
                    .frame(height: eagleAreaHeight)
                    .overlay(alignment: .top) {
                        GeometryReader { geo in
                            let side = min(geo.size.width, geo.size.height) * 0.95
                            Image("eagle_happy")
                                .resizable()
                                .scaledToFit()
                                .frame(width: side, height: side)
                                .frame(maxWidth: .infinity)
                                .offset(y: 200) // eagle only – move this to shift eagle without affecting button
                        }
                        .frame(height: eagleAreaHeight)
                    }

                // Percentage and count
                VStack(spacing: 4) {
                    Text("\(correctPercentage)%")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(buttonColor)
                    Text(selectedLanguage == .english
                        ? (totalPossiblePoints != totalQuizCount ? "\(quizPointsEarned) of \(totalPossiblePoints) points" : "\(quizCorrectCount) of \(totalQuizCount) correct")
                        : (totalPossiblePoints != totalQuizCount ? "\(quizPointsEarned) из \(totalPossiblePoints) баллов" : "Правильно: \(quizCorrectCount) из \(totalQuizCount)"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

            Button {
                Task {
                    let uid: UUID? = {
                        guard let s = UserDefaults.standard.string(forKey: "currentUserId") else { return nil }
                        return UUID(uuidString: s)
                    }()
                    await addVocabularyWordsForLesson(cloudIndex: cloudIndex, userId: uid)
                    await saveLessonProgress()
                    onComplete?()
                    await MainActor.run { dismiss() }
                }
            } label: {
                Text(selectedLanguage == .english ? "Back to lessons" : "К урокам")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(buttonColor))
                        .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
            }
            .offset(y: -140)
            Spacer()
        }
    }

    private func saveLessonProgress() async {
        let userId = (UserDefaults.standard.string(forKey: "currentUserId")).flatMap { UUID(uuidString: $0) }
        let key = currentLessonStorageKey(userId: userId)
        var current = UserDefaults.standard.integer(forKey: key)
        if current < 1 { current = 1 }
        let newVal = min(CourseStructure.totalClouds, max(current, cloudIndex + 1))
        UserDefaults.standard.set(newVal, forKey: key)
        if let userId = userId {
            try? await SupabaseService.shared.saveNumLevel(userId: userId, numLevel: newVal)
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(buttonColor)
            Text(loadError ?? (selectedLanguage == .english ? "Could not load lesson" : "Не удалось загрузить урок"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                Task { await loadContent() }
            } label: {
                Text(selectedLanguage == .english ? "Retry" : "Повторить")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(buttonColor))
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    private func eagleBubbleView(text: String) -> some View {
        HStack {
            Spacer()
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(text)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(4)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    Path { p in p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 20, y: 0)); p.addLine(to: CGPoint(x: 10, y: 15)); p.closeSubpath() }
                        .fill(Color.white)
                        .frame(width: 20, height: 15)
                        .offset(x: -40, y: -2)
                }
                .padding(.trailing, 95)
                .padding(.top, -40)
            }
        }
    }

    private func eagleImageView(name: String, moveDown: Bool = false) -> some View {
        VStack {
            HStack { Spacer() }
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300, maxHeight: 300)
                .padding(.top, moveDown ? -30 : -80)
                .padding(.trailing, -30)
            Spacer()
        }
        .allowsHitTesting(false)
    }

    /// Build a summary of prior lessons (clouds 1..<cloudIndex) for Gemini's context.
    private func buildPriorLessonsSummary(upTo currentCloud: Int) -> String? {
        guard currentCloud > 1 else { return nil }
        let summaries = (1..<currentCloud).compactMap { idx -> String? in
            CourseStructure.node(for: idx)?.summary
        }
        guard !summaries.isEmpty else { return nil }
        return summaries.enumerated().map { "Lesson \($0.offset + 1): \($0.element)" }.joined(separator: "\n")
    }

    private func loadContent() async {
        guard let node = node else {
            await MainActor.run { loadError = "Invalid lesson"; isLoading = false }
            return
        }
        await MainActor.run { isLoading = true; loadError = nil }
        let cacheKey = lessonContentCacheKeyPrefix + "\(cloudIndex)"
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode(GeneratedLessonContent.self, from: data) {
            await MainActor.run {
                content = decoded
                isLoading = false
            }
            return
        }
        do {
            let priorSummary = buildPriorLessonsSummary(upTo: cloudIndex)
            let generated = try await SupabaseService.shared.generateCourseContent(
                for: node.summary,
                priorLessonsSummary: priorSummary,
                cloudIndex: cloudIndex
            )
            await MainActor.run {
                content = generated
                isLoading = false
            }
            if let data = try? JSONEncoder().encode(generated) {
                UserDefaults.standard.set(data, forKey: cacheKey)
            }
        } catch {
            // Use real bundled lesson for this cloud (Kazakh content, proper questions) — don't cache so we can retry API later
            let bundled = GeneratedLessonContent.bundled(for: cloudIndex, english: selectedLanguage == .english)
            await MainActor.run {
                content = bundled
                isLoading = false
            }
        }
    }
}

private struct ConnectSlotView: View {
    let text: String?
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(text ?? "_____")
                .font(.title2)
                .foregroundColor(text != nil ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// Reuse the same AnswerButton style as in LanguageTestView (defined there as private; we duplicate for this file).
private struct AnswerButton: View {
    let text: String
    let isSelected: Bool
    let accentColor: Color
    var showAsCorrect: Bool = false
    var showAsWrong: Bool = false
    var isLarge: Bool = false
    var isSlightlyLarger: Bool = false
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
                .font(isLarge ? .title2 : (isSlightlyLarger ? .title3 : .headline))
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity)
                .frame(minHeight: isLarge ? 100 : nil)
                .padding(.horizontal, isLarge ? 24 : (isSlightlyLarger ? 20 : 0))
                .padding(.vertical, isLarge ? 24 : (isSlightlyLarger ? 20 : 16))
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(fillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(strokeColor, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// Renders text with **highlighted** segments in accent color (for Gemini-generated slides).
private struct HighlightedTextView: View {
    let text: String
    let highlightColor: Color

    var body: some View {
        let parts = text.components(separatedBy: "**")
        let result = parts.enumerated().reduce(Text(""), { acc, item in
            let t = Text(item.element).foregroundColor(item.offset % 2 == 1 ? highlightColor : .black)
            return item.offset == 0 ? t : acc + t
        })
        return result
    }
}

#Preview {
    NavigationStack {
        CloudLessonView(cloudIndex: 1, selectedLanguage: .english)
    }
}
