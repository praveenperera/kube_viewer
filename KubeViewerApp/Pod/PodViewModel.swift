//
//  PodViewModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-07-27.
//

import Combine
import Foundation
import SwiftUI

class PodViewModel: ObservableObject, PodViewModelCallback {
    let windowId: UUID
    var data: RustPodViewModel

    @Published var pods: LoadStatus<[Pod]> = .initial

    init(windowId: UUID) {
        self.windowId = windowId
        self.data = RustPodViewModel()

        DispatchQueue.main.async { self.setupCallback() }
    }

    @MainActor
    private func setupCallback() {
        Task {
            await self.data.addCallbackListener(responder: self)
        }
    }

    @MainActor
    func callback(message: PodViewModelMessage) {
        Task {
            await MainActor.run {
                switch message {
                    case .loading:
                        self.pods = .loading

                    case let .loadingFailed(error):
                        self.pods = .error(error: error)

                    case let .loaded(pods: pods):
                        print("[swift] pods loaded")
                        self.pods = .loaded(data: pods)
                }
            }
        }
    }
}
