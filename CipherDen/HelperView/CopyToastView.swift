//
//  CopyToastView.swift
//  CipherDen
//
//  Created by hyperlink on 05/02/26.
//

import Foundation
import SwiftUI

struct CopyToastView: View {
    
    @State private var scale: CGFloat = 0.85

    var body: some View {
        Text("Copied to clipboard")
            .font(.system(size: 15, weight: .bold))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.85))
            )
            .foregroundColor(.white)
            .shadow(radius: 5)
            .scaleEffect(scale)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        scale = 1
                    }
                }
            }
    }
}
