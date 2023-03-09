//
//  KubeViewerAppApp.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

class GlobalModel: ObservableObject {
    @Published var models: [UUID: MainViewModel]

    init() {
        self.models = [:]
    }

    func getModel(_ key: UUID) -> MainViewModel? {
        self.models[key]
    }

    func windowClosing(_ windowId: UUID) {
        self.models.removeValue(forKey: windowId)
        self.models = self.models.compactMapValues { $0 }
    }
}

@main
struct KubeViewerApp: App {
    @StateObject var global = GlobalModel()

    var body: some Scene {
        WindowGroup(id: "Main", for: UUID.self) { $maybeUuid in
            let uuid = maybeUuid ?? UUID()
            let model = self.global.models[uuid] ?? MainViewModel(windowId: uuid)

            MainView(windowId: uuid, model: model)
                .environmentObject(self.global)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct Previews_KubeViewerApp_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
