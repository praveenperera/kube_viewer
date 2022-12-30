//
//  KubeViewerAppApp.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

@main
struct KubeViewerAppApp: App {
    var body: some Scene {
        let mainWindow = WindowGroup {
            ContentView()
        }
        mainWindow.commands {
            CommandGroup(after: .newItem) {
                Button(action: {
                    if let currentWindow = NSApp.keyWindow,
                       let windowController = currentWindow.windowController {
                        windowController.newWindowForTab(nil)
                        if let newWindow = NSApp.keyWindow,
                           currentWindow != newWindow {
                            currentWindow.addTabbedWindow(newWindow, ordered: .above)
                        }
                    }
                }) {
                    Text("New Tab")
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
        }
    }
}
