//
//  PaymentPageView.swift
//  OYAN App
//
//  Placeholder payment page shown when user hits chat usage limit.
//

import SwiftUI

struct PaymentPageView: View {
    let selectedLanguage: Language
    @Environment(\.dismiss) private var dismiss

    private let backgroundColor = Color(hex: "#fbf5e0")
    private let buttonColor = Color(hex: "#ffa812")

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 64))
                    .foregroundColor(buttonColor)
                Text(selectedLanguage == .english
                    ? "The payment page is currently in development:)"
                    : "Страница оплаты сейчас в разработке:)")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .english ? "Close" : "Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(buttonColor)
                }
            }
        }
    }
}

#Preview {
    PaymentPageView(selectedLanguage: .english)
}
