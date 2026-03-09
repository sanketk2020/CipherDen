//
//  EditableTextView.swift
//  CipherDen
//
//  Created by hyperlink on 23/01/26.
//

import Foundation
import SwiftUI

struct EditableTextView: NSViewRepresentable {

    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {

        let textView = NSTextView()

        // Editable behavior
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true

        // Appearance
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 8, height: 10)
        textView.backgroundColor = NSColor.textBackgroundColor

        // CRITICAL for older macOS
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        // Delegate
        textView.delegate = context.coordinator
        textView.string = text

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        // 🔑 MOST IMPORTANT LINE
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {

        guard let textView = nsView.documentView as? NSTextView else { return }

        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {

        var parent: EditableTextView

        init(_ parent: EditableTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {

            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
