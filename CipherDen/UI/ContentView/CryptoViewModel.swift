//
//  CryptoViewModel.swift
//  CipherDen
//
//  Created by hyperlink on 23/01/26.
//

import Foundation
import RNCryptor
import Combine

class CryptoViewModel: ObservableObject {

    @Published var inputText = ""
    @Published var outputText = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    @Published var errorMessage = ""
    @Published var copyStatus = ""

    // MARK: - Public Actions

    func encrypt() {
        handleCrypto(mode: .encrypt)
    }

    func decrypt() {
        handleCrypto(mode: .decrypt)
    }

    // MARK: - Core Logic

    private func handleCrypto(mode: CryptoMode) {

        errorMessage = ""
        copyStatus = ""

        guard let result = processCrypto(
            input: inputText,
            password: password,
            mode: mode
        ) else {

            // ✅ Clear result on error
            outputText = ""

            errorMessage = "❌ Operation failed. Please check input or password."
            return
        }

        outputText = result
    }

    // MARK: - Copy Output

    func copyOutput() {

        guard !outputText.isEmpty else {
            copyStatus = "Nothing to copy"
            return
        }

        copyToClipboard(outputText)

        copyStatus = "✅ Copied to clipboard"

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.copyStatus = ""
        }
    }
    
    // MARK: - Clear All

    func clearAll() {

        inputText = ""
        outputText = ""
        errorMessage = ""
        copyStatus = ""
        isPasswordVisible = false   // Optional: auto hide password
    }
}
