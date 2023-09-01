//
//  PodViewModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-07-27.

import Combine
import Foundation
import SwiftUI

class PodViewModel: ObservableObject, PodViewModelCallback {
    let windowId: UUID
    var data: RustPodViewModel

    @Published var pods: LoadStatus<[Pod]> = .initial

    @Published var toastWarning: String? = nil
    @Published var toastError: String? = nil

    init(windowId: UUID) {
        self.windowId = windowId
        self.data = RustPodViewModel()
    }

    func getDataAndSetupWatcher(_ selectedCluster: ClusterId) async {
        // idempotent function
        await self.data.initializeModelWithResponder(responder: self)
        await self.data.fetchPods(selectedCluster: selectedCluster)
        await self.data.startWatcher(selectedCluster: selectedCluster)
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

                    case let .toastWarningMessage(message: message):
                        self.toastWarning = message

                    case let .toastErrorMessage(message: message):
                        self.toastError = message
                }
            }
        }
    }
}
