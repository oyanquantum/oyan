//
//  HomeView.swift
//  OYAN App
//
//  Main page: progress bar, streak (sun), cloud lessons, bottom bar (Profile, Home, Vocabulary).
//

import SwiftUI

private let dailyStudyMinutesKey = "dailyStudyMinutesGoal"
private let todayStudySecondsKey = "todayStudySeconds"
private let lastStudyDateKey = "lastStudyDate"

enum MainTab: Int {
    case lessons = 0   // clouds
    case alphabet = 1
    case vocabulary = 2
    case chat = 3
    case profile = 4
}

struct HomeView: View {
    let selectedLanguage: Language

    @State private var selectedTab: MainTab = .lessons
    @State private var progress: Double = 0
    @State private var showLesson = false
    @State private var tappedCloudIndex: Int = 1
    /// Highest lesson (cloud) the user can access. 1 = only cloud 1 unlocked.
    @State private var currentLesson: Int = 1

    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")

    private var dailyGoalMinutes: Int {
        let stored = UserDefaults.standard.integer(forKey: dailyStudyMinutesKey)
        return stored > 0 ? stored : 10
    }

    /// User's Kazakh level from placement test (saved locally or from server)
    private var levelDisplayName: String {
        let raw = UserDefaults.standard.string(forKey: "savedKnowledgeLevel") ?? ""
        let level = KazakhLevel(rawValue: raw) ?? .beginner
        return level.displayName(english: selectedLanguage == .english)
    }

    private var todayStudySeconds: Int {
        get {
            ensureTodayStudyState()
            return UserDefaults.standard.integer(forKey: todayStudySecondsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: todayStudySecondsKey)
            UserDefaults.standard.set(todayString(), forKey: lastStudyDateKey)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom

            ZStack {
                // Background: one layer so layout doesn't change between tabs
                ZStack {
                    backgroundColor.ignoresSafeArea()
                    if selectedTab == .lessons {
                        Image("lessons_background")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    }
                }

                VStack(spacing: 0) {
                    // Top bar: fixed position using safe area (extra top padding pushes bar lower)
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, max(0, safeTop) + 50)
                        .padding(.bottom, 6)

                    // Content: same height region for every tab (no vertical shift)
                    Group {
                        switch selectedTab {
                        case .lessons:
                            lessonsContent
                        case .alphabet:
                            AlphabetView(selectedLanguage: selectedLanguage)
                        case .vocabulary:
                            VocabularyView(selectedLanguage: selectedLanguage)
                        case .chat:
                            ChatView(selectedLanguage: selectedLanguage, currentLesson: currentLesson)
                        case .profile:
                            ProfileView(selectedLanguage: selectedLanguage)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(minHeight: 0)

                    // Bottom bar: extra bottom padding pushes menu higher
                    bottomBar
                        .padding(.bottom, max(0, safeBottom) + 24)
                }
            }
        }
        .ignoresSafeArea(edges: .all)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            updateProgress()
            Task { await syncProgressFromSupabase() }
            refreshCurrentLesson()
        }
        .onChange(of: showLesson) { _, isShowing in
            if !isShowing {
                Task { await syncProgressFromSupabase() }
                refreshCurrentLesson()
            }
        }
        .navigationDestination(isPresented: $showLesson) {
            CloudLessonView(cloudIndex: tappedCloudIndex, selectedLanguage: selectedLanguage, onComplete: {
                refreshCurrentLesson()
            })
        }
    }

    private var topBar: some View {
        VStack(spacing: 4) {
            // Level label above the streak bar
            Text(levelDisplayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Progress bar row
            HStack(alignment: .center, spacing: 16) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(buttonColor.opacity(0.4), lineWidth: 1)
                            )
                        RoundedRectangle(cornerRadius: 8)
                            .fill(buttonColor)
                            .frame(width: max(0, geo.size.width * progress))
                    }
                }
                .frame(height: 12)
                .fixedSize(horizontal: false, vertical: true)

                // Streak: sun (grey until bar full, then yellow and shiny)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 28))
                    .foregroundColor(progress >= 1 ? Color.yellow : Color.gray.opacity(0.6))
                    .shadow(color: progress >= 1 ? Color.yellow.opacity(0.9) : .clear, radius: 10)
                    .shadow(color: progress >= 1 ? Color.orange.opacity(0.6) : .clear, radius: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
    }

    private var lessonsContent: some View {
        GeometryReader { outer in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    // Cloud path: 12 clouds (1 at bottom → scroll up for 2…12)
                    cloudPath
                        .frame(width: outer.size.width, height: 1500)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    // Anchor at bottom so we can start scrolled to cloud 1
                    Color.clear
                        .frame(height: 1)
                        .id("cloudPathBottom")
                }
                .frame(maxWidth: .infinity)
                .clipped()
                .onAppear {
                    // Start at cloud 1 (bottom); user scrolls up to see next clouds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("cloudPathBottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 11 positions: equal vertical spacing, S-curve for x. Cloud 1 at bottom, 11 at top.
    private static let cloudPathPositions: [(CGFloat, CGFloat)] = [
        (0.22, 0.95),   // 1  bottom, left
        (0.45, 0.868),  // 2
        (0.70, 0.786),  // 3
        (0.82, 0.705),  // 4
        (0.65, 0.623),  // 5  curve left
        (0.38, 0.541),  // 6
        (0.18, 0.459),  // 7
        (0.40, 0.367),  // 8
        (0.68, 0.295),  // 9
        (0.76, 0.214),  // 10
        (0.48, 0.132),  // 11 (golden, right after 10)
    ]

    private var cloudPath: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(0..<CourseStructure.totalClouds, id: \.self) { index in
                    let cloudIndex = index + 1
                    let pos = Self.cloudPathPositions[index]
                    let isGolden = CourseStructure.isGolden(cloudIndex: cloudIndex)
                    let isLocked = cloudIndex > currentLesson
                    CloudButton(
                        index: cloudIndex,
                        accentColor: buttonColor,
                        isGolden: isGolden,
                        isLocked: isLocked
                    ) {
                        tappedCloudIndex = cloudIndex
                        showLesson = true
                    }
                    .position(
                        x: geo.size.width * pos.0,
                        y: geo.size.height * pos.1
                    )
                }
                ForEach(Array(CourseStructure.sectionDividers(english: selectedLanguage == .english).enumerated()), id: \.offset) { _, div in
                    SectionDivider(title: div.title, accentColor: buttonColor)
                        .frame(width: geo.size.width - 32)
                        .position(x: geo.size.width / 2, y: geo.size.height * div.y)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: 1500)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            bottomBarButton(
                icon: "house.fill",
                label: selectedLanguage == .english ? "Home" : "Главная",
                tab: .lessons
            )
            bottomBarButton(
                icon: "textformat.abc",
                label: selectedLanguage == .english ? "Alphabet" : "Алфавит",
                tab: .alphabet
            )
            bottomBarButton(
                icon: "book.closed.fill",
                label: selectedLanguage == .english ? "Vocabulary" : "Словарь",
                tab: .vocabulary
            )
            bottomBarButton(
                icon: "bubble.left.and.bubble.right.fill",
                label: selectedLanguage == .english ? "Chat" : "Чат",
                tab: .chat
            )
            bottomBarButton(
                icon: "person.fill",
                label: selectedLanguage == .english ? "Profile" : "Профиль",
                tab: .profile
            )
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(buttonColor.opacity(0.2)),
            alignment: .top
        )
    }

    private func bottomBarButton(icon: String, label: String, tab: MainTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedTab == tab ? buttonColor : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func ensureTodayStudyState() {
        let last = UserDefaults.standard.string(forKey: lastStudyDateKey) ?? ""
        if last != todayString() {
            UserDefaults.standard.set(0, forKey: todayStudySecondsKey)
            UserDefaults.standard.set(todayString(), forKey: lastStudyDateKey)
        }
    }

    private func updateProgress() {
        ensureTodayStudyState()
        let goalSeconds = dailyGoalMinutes * 60
        let seconds = UserDefaults.standard.integer(forKey: todayStudySecondsKey)
        progress = goalSeconds > 0 ? min(1, Double(seconds) / Double(goalSeconds)) : 0
    }

    private func refreshCurrentLesson() {
        let userId = (UserDefaults.standard.string(forKey: "currentUserId")).flatMap { UUID(uuidString: $0) }
        let key = currentLessonStorageKey(userId: userId)
        var val = UserDefaults.standard.integer(forKey: key)
        if val < 1 { val = 1 }
        if val > CourseStructure.totalClouds { val = CourseStructure.totalClouds }
        currentLesson = val
    }

    /// Sync lesson progress from Supabase so unlocks persist across devices. Uses max(local, server).
    private func syncProgressFromSupabase() async {
        guard let userIdStr = UserDefaults.standard.string(forKey: "currentUserId"),
              let userId = UUID(uuidString: userIdStr) else { return }
        guard let profile = try? await SupabaseService.shared.getUserProfile(userId: userId) else { return }
        let serverLevel = profile.numLevel ?? 1
        let key = currentLessonStorageKey(userId: userId)
        let local = UserDefaults.standard.integer(forKey: key)
        let newVal = min(CourseStructure.totalClouds, max(1, max(local, serverLevel)))
        if newVal != local {
            await MainActor.run {
                UserDefaults.standard.set(newVal, forKey: key)
                refreshCurrentLesson()
            }
        }
    }
}

// MARK: - Section divider (centered title with horizontal lines)
private struct SectionDivider: View {
    let title: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            line
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(accentColor.opacity(0.4))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Cloud (tappable lesson node) — regular or golden; locked clouds show lock icon
private struct CloudButton: View {
    let index: Int
    let accentColor: Color
    var isGolden: Bool = false
    var isLocked: Bool = false
    let onTap: () -> Void

    private var cloudImageName: String { isGolden ? "cloud_golden" : "cloud" }

    var body: some View {
        Button {
            if !isLocked { onTap() }
        } label: {
            ZStack {
                Image(cloudImageName)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)

                Text("\(index)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .frame(width: 276, height: 216)
        }
        .buttonStyle(.plain)
    }
}

// Call this when the user completes lesson time (e.g. from a lesson screen)
func addStudyTimeSeconds(_ seconds: Int) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let today = formatter.string(from: Date())
    if UserDefaults.standard.string(forKey: lastStudyDateKey) != today {
        UserDefaults.standard.set(0, forKey: todayStudySecondsKey)
    }
    UserDefaults.standard.set(today, forKey: lastStudyDateKey)
    let current = UserDefaults.standard.integer(forKey: todayStudySecondsKey)
    UserDefaults.standard.set(current + seconds, forKey: todayStudySecondsKey)
}

#Preview {
    NavigationStack {
        HomeView(selectedLanguage: .english)
    }
}
