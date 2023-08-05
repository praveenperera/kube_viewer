//
//  KubeViewerAppApp.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

struct ViewModels {
    var main: MainViewModel
    var nodes: NodeViewModel?
    var pods: PodViewModel?
}

class GlobalModel: ObservableObject {
    var models: [UUID: ViewModels]

    init() {
        self.models = [:]
    }

    func mainWindowModel(_ windowId: UUID) -> MainViewModel? {
        self.models[windowId]?.main
    }

    func windowOpened(_ windowId: UUID) {}

    func windowClosing(_ windowId: UUID) {
        self.models[windowId]?.main.data.setWindowClosed()
    }
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
