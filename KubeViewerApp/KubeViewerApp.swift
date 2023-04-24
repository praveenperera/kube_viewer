//
//  KubeViewerAppApp.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

class GlobalModel: ObservableObject {
    var models: [UUID: MainViewModel]

    init() {
        self.models = [:]
    }

    func windowModel(_ windowId: UUID) -> MainViewModel? {
        self.models[windowId]
    }

    func windowOpened(_ windowId: UUID) {
        self.models[windowId]?.data.setWindowClosed()
    }

    func windowClosing(_ windowId: UUID) {}
}

@main
struct KubeViewerApp: App {
    @StateObject var global = GlobalModel()

    var body: some Scene {
        WindowGroup(id: "Main", for: UUID.self) { $uuid in
            MainView(windowId: $uuid, globalModel: self.global)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct Previews_KubeViewerApp_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
