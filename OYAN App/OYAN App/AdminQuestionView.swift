//
//  AdminQuestionView.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import SwiftUI
import Supabase

enum QuestionDifficulty: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var id: String { rawValue }
}

struct AdminQuestionView: View {
    @State private var questionText: String = ""
    @State private var correctAnswer: String = ""
    @State private var wrongOption1: String = ""
    @State private var wrongOption2: String = ""
    @State private var wrongOption3: String = ""
    @State private var selectedDifficulty: QuestionDifficulty = .beginner
    @State private var isLoading: Bool = false
    
    // Color scheme
    let backgroundColor = Color(hex: "#fbf5e0")
    let buttonColor = Color(hex: "#ffa812")
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 20)
                    
                    // Title
                    Text("Upload Question")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    // Question Text Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question Text")
                            .font(.headline)
                        TextField("Enter question text", text: $questionText)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 30)
                    
                    // Correct Answer Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Correct Answer")
                            .font(.headline)
                        TextField("Enter correct answer", text: $correctAnswer)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 30)
                    
                    // Wrong Option 1
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wrong Option 1")
                            .font(.headline)
                        TextField("Enter wrong option", text: $wrongOption1)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 30)
                    
                    // Wrong Option 2
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wrong Option 2")
                            .font(.headline)
                        TextField("Enter wrong option", text: $wrongOption2)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 30)
                    
                    // Wrong Option 3
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wrong Option 3")
                            .font(.headline)
                        TextField("Enter wrong option", text: $wrongOption3)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 30)
                    
                    // Difficulty Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Difficulty")
                            .font(.headline)
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            ForEach(QuestionDifficulty.allCases) { difficulty in
                                Text(difficulty.rawValue).tag(difficulty)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 30)
                    
                    // Upload Button
                    Button(action: uploadQuestion) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Upload Question")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isLoading ? buttonColor.opacity(0.6) : buttonColor)
                        )
                        .shadow(color: buttonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isLoading || questionText.isEmpty || correctAnswer.isEmpty || wrongOption1.isEmpty || wrongOption2.isEmpty || wrongOption3.isEmpty)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func uploadQuestion() {
        // Combine wrong options into an array
        let wrongOptions: [String] = [wrongOption1, wrongOption2, wrongOption3]
        
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                // Create the question data structure
                struct QuestionInsert: Encodable {
                    let question_text: String
                    let correct_answer: String
                    let wrong_options: [String]
                    let difficulty: String
                }
                
                let questionData = QuestionInsert(
                    question_text: questionText,
                    correct_answer: correctAnswer,
                    wrong_options: wrongOptions,
                    difficulty: selectedDifficulty.rawValue
                )
                
                // Insert into Supabase
                try await SupabaseManager.shared.client
                    .from("questions")
                    .insert(questionData)
                    .execute()
                
                await MainActor.run {
                    isLoading = false
                    print("Success")
                    
                    // Clear form after successful upload
                    questionText = ""
                    correctAnswer = ""
                    wrongOption1 = ""
                    wrongOption2 = ""
                    wrongOption3 = ""
                    selectedDifficulty = .beginner
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AdminQuestionView()
    }
}
