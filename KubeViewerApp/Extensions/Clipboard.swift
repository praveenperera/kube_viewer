//
//  Clipboard.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-09-08.
//

import Foundation

#if os(macOS)
import AppKit
typealias Clipboard = NSPasteboard
#else
import UIKit
typealias Clipboard = UIPasteboard
#endif

extension Clipboard {
    func copyText(_ text: String) {
#if os(macOS)
        self.clearContents()
        self.setString(text, forType: .string)
#else
        self.string = text
#endif
    }
}
