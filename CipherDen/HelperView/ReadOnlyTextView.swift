//
//  ReadOnlyTextView.swift
//  CipherDen
//
//  Created by hyperlink on 23/01/26.
//

import SwiftUI
import AppKit

struct ReadOnlyTextView: NSViewRepresentable {

    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {

        let textView = NSTextView()

        // MARK: - Read-only behavior
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = false

        // MARK: - Appearance
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 8, height: 10)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.string = text

        // MARK: - Layout (critical for old macOS)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
}
