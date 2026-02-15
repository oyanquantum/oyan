//
//  ChatView.swift
//  OYAN App
//
//  Chat with OYAN the eagle — message list, avatar, text field.
//

import SwiftUI

/// OYAN avatar. Replace oyan_chat_pfp.png in Assets with your custom eagle/OYAN photo.
private let oyanAvatarName = "oyan_chat_pfp"

struct ChatView: View {
    let selectedLanguage: Language
    /// Highest lesson completed (1–11). Used for prior-lessons summary so the tutor adapts to user level.
    let currentLesson: Int

    @StateObject private var viewModel = ChatViewModel()
    @State private var keyboardHeight: CGFloat = 0
    @State private var showPaymentPage: Bool = false

    init(selectedLanguage: Language, currentLesson: Int = 1) {
        self.selectedLanguage = selectedLanguage
        self.currentLesson = max(1, min(currentLesson, CourseStructure.totalClouds))
    }

    private let backgroundColor = Color(hex: "#fbf5e0")
    private let buttonColor = Color(hex: "#ffa812")

    private var chatHeader: some View {
        HStack(spacing: 12) {
            OyanAvatarView(size: 44, imageName: oyanAvatarName)
            VStack(alignment: .leading, spacing: 2) {
                Text("OYAN")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(selectedLanguage == .english ? "Kazakh AI tutor" : "Казахский ИИ‑репетитор")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(backgroundColor)
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                selectedLanguage == .english ? "Type a message…" : "Введите сообщение…",
                text: $viewModel.inputText,
                axis: .vertical
            )
            .lineLimit(1...4)
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(buttonColor.opacity(0.4), lineWidth: 1)
            )
            .disabled(viewModel.isLoading)

            Button {
                Task { await viewModel.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.isLoading ? .gray : buttonColor)
            }
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(backgroundColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            chatHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, accentColor: buttonColor)
                        }
                        if viewModel.isLoading {
                            HStack(alignment: .top, spacing: 12) {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .scaleEffect(0.85)
                                        .tint(buttonColor)
                                    Text(selectedLanguage == .english ? "Thinking…" : "Думаю…")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.9))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(buttonColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                Spacer(minLength: 48)
                            }
                            .padding(.horizontal, 16)
                            .id("loading")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                inputBar
                    .padding(.bottom, keyboardHeight)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    if viewModel.isLoading {
                        proxy.scrollTo("loading", anchor: .bottom)
                    } else if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isLoading) { _, loading in
                if loading {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .onAppear {
            viewModel.priorLessonsSummary = CourseStructure.priorLessonsSummary(upTo: currentLesson)
            viewModel.userLanguage = selectedLanguage == .english ? "en" : "ru"
            if let idStr = UserDefaults.standard.string(forKey: "currentUserId"),
               let uid = UUID(uuidString: idStr) {
                viewModel.userId = uid
                Task { await viewModel.loadIfNeeded() }
            }
        }
        .onChange(of: currentLesson) { _, newVal in
            viewModel.priorLessonsSummary = CourseStructure.priorLessonsSummary(upTo: newVal)
        }
        .onChange(of: selectedLanguage) { _, lang in
            viewModel.userLanguage = lang == .english ? "en" : "ru"
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            // Subtract tab bar + safe area so the input bar sits just above the keyboard, not too high
            let offset = max(0, frame.height - 90)
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = offset
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
        .alert(
            selectedLanguage == .english ? "Usage limit reached" : "Лимит достигнут",
            isPresented: $viewModel.showUsageLimitAlert
        ) {
            Button(selectedLanguage == .english ? "OK" : "ОК") { }
            Button(selectedLanguage == .english ? "Pay" : "Оплатить") {
                showPaymentPage = true
            }
        } message: {
            Text(selectedLanguage == .english
                ? "You've reached your usage limit. You can continue using the chat only by paying."
                : "Вы достигли лимита использования. Продолжить можно только после оплаты.")
        }
        .sheet(isPresented: $showPaymentPage) {
            PaymentPageView(selectedLanguage: selectedLanguage)
        }
    }
}

// MARK: - OYAN Avatar (circular, for chat)

private struct OyanAvatarView: View {
    let size: CGFloat
    var imageName: String = "eagle_speech"

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color(hex: "#ffa812").opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .user { Spacer(minLength: 48) }

            Text(message.text)
                .font(.body)
                .foregroundColor(message.role == .user ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.role == .user ? accentColor : Color.white.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(message.role == .assistant ? accentColor.opacity(0.3) : .clear, lineWidth: 1)
                )

            if message.role == .assistant { Spacer(minLength: 48) }
        }
        .id(message.id)
    }
}

#Preview {
    ChatView(selectedLanguage: .english, currentLesson: 3)
}
