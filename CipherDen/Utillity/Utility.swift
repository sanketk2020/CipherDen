//
//  Utility.swift
//  CipherDen
//
//  Created by hyperlink on 23/01/26.
//

import Foundation
import AppKit
import RNCryptor

enum CryptoMode {
    case encrypt
    case decrypt
}

func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

func prettyPrintedJSON(from jsonString: String) -> String? {
    guard let data = jsonString.data(using: .utf8) else { return nil }
    do {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyData = try JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys]
        )
        return String(data: prettyData, encoding: .utf8)
    } catch {
        return nil
    }
}

func processCrypto(input: String, password: String, mode: CryptoMode) -> String? {

    guard !input.isEmpty else {
        print("Input is empty")
        return nil
    }

    guard !password.isEmpty else {
        print("Password is empty")
        return nil
    }

    do {

        switch mode {

        case .encrypt:

            let data = Data(input.utf8)

            let encryptedData = try RNCryptor.encrypt(
                data: data,
                withPassword: password
            )

            return encryptedData.base64EncodedString()

        case .decrypt:

            guard let encryptedData = Data(
                base64Encoded: input,
                options: .ignoreUnknownCharacters
            ) else {
                print("Invalid Base64 input")
                return nil
            }

            let decryptedData = try RNCryptor.decrypt(
                data: encryptedData,
                withPassword: password
            )

            guard let decryptedString = String(
                data: decryptedData,
                encoding: .utf8
            ) else {
                print("Invalid UTF-8 output")
                return nil
            }

            // ✅ Beautify JSON if possible
            if let prettyJSON = prettyPrintedJSON(from: decryptedString) {
                return prettyJSON
            }

            // Fallback if not valid JSON
            return decryptedString
        }

    } catch {
        print("Crypto operation failed: \(error)")
        return nil
    }
}


//func processCrypto(input: String, password: String, mode: CryptoMode) -> String? {
//    
//    guard !input.isEmpty else {
//        print("Input is empty")
//        return nil
//    }
//    
//    guard !password.isEmpty else {
//        print("Password is empty")
//        return nil
//    }
//    
//    do {
//        
//        switch mode {
//            
//        case .encrypt:
//            
//            let data = Data(input.utf8)
//            
//            let encryptedData = try RNCryptor.encrypt(
//                data: data,
//                withPassword: password
//            )
//            
//            return encryptedData.base64EncodedString()
//            
//        case .decrypt:
//            
//            guard let encryptedData = Data(
//                base64Encoded: input,
//                options: .ignoreUnknownCharacters
//            ) else {
//                print("Invalid Base64 input")
//                return nil
//            }
//            
//            let decryptedData = try RNCryptor.decrypt(
//                data: encryptedData,
//                withPassword: password
//            )
//            
//            guard let decryptedString = String(
//                data: decryptedData,
//                encoding: .utf8
//            ) else {
//                print("Invalid UTF-8 output")
//                return nil
//            }
//            
//            return decryptedString
//        }
//        
//    } catch {
//        print("Crypto operation failed: \(error)")
//        return nil
//    }
//}
