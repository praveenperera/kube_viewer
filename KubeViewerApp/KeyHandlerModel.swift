//
//  KeyHandlerModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2/23/23.
//

import Foundation

class KeyHandlerModel: ObservableObject {
    @Published var focusRegion: FocusRegion

    init() {
        self.focusRegion = .sidebar
    }
}
