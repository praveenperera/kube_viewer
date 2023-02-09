//
//  KubeViewerAppApp.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

@main
struct KubeViewerApp: App {
    var body: some Scene {
        let mainWindow = WindowGroup {
            MainView()
        }.windowStyle(.hiddenTitleBar)

        mainWindow.commands {
            CommandGroup(after: .newItem) {
                Button(action: {
                    if let currentWindow = NSApp.keyWindow,
                       let windowController = currentWindow.windowController
                    {
                        windowController.newWindowForTab(nil)

                        if let newWindow = NSApp.keyWindow,
                           currentWindow != newWindow
                        {
                            currentWindow.addTabbedWindow(newWindow, ordered: .above)
                            // currentWindow.tabbingMode = .preferred
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
