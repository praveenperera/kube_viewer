//
//  KeyAware.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2/23/23.
//

import Foundation
import KeyboardShortcuts
import SwiftUI

struct KeyAwareView: NSViewRepresentable {
    let onEvent: (Event) -> Bool

    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onEvent = onEvent
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension KeyAwareView {
    enum Event {
        case upArrow
        case downArrow
        case leftArrow
        case rightArrow
        case space
        case delete
        case tab
        case shiftTab
    }
}

private class KeyView: NSView {
    var onEvent: (KeyAwareView.Event) -> Bool = { _ in false }

    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
        let preventDefault: Bool = {
            switch Int(event.keyCode) {
            case KeyboardShortcuts.Key.delete.rawValue:
                return onEvent(.delete)
            case KeyboardShortcuts.Key.upArrow.rawValue:
                return onEvent(.upArrow)
            case KeyboardShortcuts.Key.downArrow.rawValue:
                return onEvent(.downArrow)
            case KeyboardShortcuts.Key.leftArrow.rawValue:
                return onEvent(.leftArrow)
            case KeyboardShortcuts.Key.rightArrow.rawValue:
                return onEvent(.rightArrow)
            case KeyboardShortcuts.Key.space.rawValue:
                return onEvent(.space)
            case KeyboardShortcuts.Key.tab.rawValue where event.modifierFlags.contains(.shift):
                return onEvent(.shiftTab)
            case KeyboardShortcuts.Key.tab.rawValue:
                return onEvent(.tab)
            default:
                return false
            }
        }()

        if !preventDefault {
            super.keyDown(with: event)
        }
    }
}
