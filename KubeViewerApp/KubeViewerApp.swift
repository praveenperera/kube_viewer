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

    func getModel(_ key: UUID) -> MainViewModel? {
        self.models[key]
    }

    func getOrInsert(key: UUID, model: (_ windowId: UUID) -> MainViewModel) -> MainViewModel {
        if let model = self.getModel(key) {
            return model
        }

        let model = model(key)
        self.models[key] = model

        return model
    }

    func windowClosing(_ windowId: UUID) {
        self.models.removeValue(forKey: windowId)
    }
}

@main
struct KubeViewerApp: App {
    @StateObject var global = GlobalModel()

    var body: some Scene {
        WindowGroup(id: "Main", for: UUID.self) { $maybeUuid in
            let uuid = maybeUuid ?? UUID()
            let model = self.global.getOrInsert(key: uuid, model: MainViewModel.init)

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
