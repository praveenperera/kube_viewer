//
//  KubeViewerAppApp.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

@main
struct KubeViewerApp: App {
    @State private var window: NSWindow?
    @StateObject private var model = MainViewModel();
    
    var body: some Scene {
        let mainWindow = WindowGroup {
            MainView(model: model)
        }
            
            mainWindow.background(WindowAccessor(window: $window))

        
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
                        
                        currentWindow.tabbingMode = .preferred
                    }
                }) {
                    Text("New Tab")
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
        }
        
    }
}

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
