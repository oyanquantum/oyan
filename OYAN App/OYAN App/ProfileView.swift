//
//  ProfileView.swift
//  OYAN App
//

import SwiftUI

struct ProfileView: View {
    let selectedLanguage: Language

    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")

    @State private var profile: UserProfile?
    @State private var isLoading = true
    @State private var loadError: String?

    private var currentUserId: UUID? {
        guard let idString = UserDefaults.standard.string(forKey: "currentUserId") else { return nil }
        return UUID(uuidString: idString)
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .scaleEffect(1.4)
            } else if let profile = profile {
                ScrollView {
                    VStack(spacing: 0) {
                        // Center-aligned top: profile icon
                        defaultProfileIcon
                            .padding(.top, 28)

                        // Name (below picture)
                        Text(profile.fullName.isEmpty ? (selectedLanguage == .english ? "No name set" : "Имя не указано") : profile.fullName)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.top, 16)

                        // Username (below name)
                        Text(profile.username ?? "")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 6)

                        // Data rows: Age, Level, Unit, Lesson, Reason, Time
                        VStack(alignment: .leading, spacing: 14) {
                            profileRowCard(
                                label: selectedLanguage == .english ? "Age:" : "Возраст:",
                                value: profile.age.map { "\($0)" } ?? "—"
                            )
                            profileRowCard(
                                label: selectedLanguage == .english ? "Level:" : "Уровень:",
                                value: levelDisplay(profile.level ?? profile.knowledgeLevel, language: selectedLanguage)
                            )
                            profileRowCard(
                                label: selectedLanguage == .english ? "Unit:" : "Блок:",
                                value: profile.currentUnit.map { "\($0)" } ?? unitDisplay(profile.numLevel)
                            )
                            profileRowCard(
                                label: selectedLanguage == .english ? "Lesson:" : "Урок:",
                                value: profile.numLevel.map { "\($0)" } ?? "1"
                            )
                            profileRowCard(
                                label: selectedLanguage == .english ? "Reason:" : "Причина:",
                                value: reasonDisplay(profile.reasonForStudying, language: selectedLanguage)
                            )
                            profileRowCard(
                                label: selectedLanguage == .english ? "Time:" : "Время:",
                                value: timeDisplay(minutes: profile.studyTimeMinutes)
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer(minLength: 24)

                        // Log out at bottom
                        Button {
                            UserDefaults.standard.removeObject(forKey: "currentUserId")
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text(selectedLanguage == .english ? "Log out" : "Выйти")
                                    .font(.headline)
                            }
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                        Spacer(minLength: 32)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text(loadError ?? (selectedLanguage == .english ? "Could not load profile" : "Не удалось загрузить профиль"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear { Task { await loadProfile() } }
    }

    private var defaultProfileIcon: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 104))
            .foregroundColor(buttonColor)
    }

    private func profileRowCard(label: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(buttonColor.opacity(0.3), lineWidth: 1)
        )
    }

    private func levelDisplay(_ level: String?, language: Language) -> String {
        guard let level = level, !level.isEmpty else { return "—" }
        let lower = level.lowercased()
        if let kazakhLevel = KazakhLevel(rawValue: lower) {
            return kazakhLevel.displayName(english: language == .english)
        }
        return level.prefix(1).uppercased() + level.dropFirst().lowercased()
    }

    /// Unit 1 = lessons 1–4, Unit 2 = 5–7, Unit 3 = 8–11.
    private func unitDisplay(_ lessonNum: Int?) -> String {
        guard let n = lessonNum, n >= 1 else { return "1" }
        if n <= 4 { return "1" }
        if n <= 7 { return "2" }
        return "3"
    }

    private func reasonDisplay(_ reason: String?, language: Language) -> String {
        guard let reason = reason, !reason.isEmpty else { return "—" }
        if let learningReason = KazakhLearningReason(rawValue: reason) {
            return learningReason.title(for: language)
        }
        return reason.prefix(1).uppercased() + reason.dropFirst().lowercased()
    }

    private func timeDisplay(minutes: Int?) -> String {
        guard let min = minutes else { return "—" }
        if selectedLanguage == .english {
            return min == 1 ? "1 minute" : "\(min) minutes"
        } else {
            return min == 1 ? "1 минута" : "\(min) минут"
        }
    }

    private func loadProfile() async {
        guard let userId = currentUserId else {
            await MainActor.run {
                loadError = selectedLanguage == .english ? "Not logged in" : "Вы не вошли"
                isLoading = false
            }
            return
        }
        do {
            let p = try await SupabaseService.shared.getUserProfile(userId: userId)
            await MainActor.run {
                profile = p
                isLoading = false
                loadError = nil
                // Never downgrade: sync lesson progress using max(local, server) so exiting a lesson doesn't relock it
                let serverLesson = max(1, min(CourseStructure.totalClouds, p.numLevel ?? 1))
                let key = currentLessonStorageKey(userId: userId)
                let local = UserDefaults.standard.integer(forKey: key)
                let synced = max(local, serverLesson)
                if synced != local {
                    UserDefaults.standard.set(synced, forKey: key)
                }
            }
        } catch {
            await MainActor.run {
                loadError = selectedLanguage == .english ? "Could not load profile" : "Не удалось загрузить профиль"
                isLoading = false
            }
        }
    }
}

#Preview {
    ProfileView(selectedLanguage: .english)
}
