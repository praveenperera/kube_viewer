//
//  PodViewModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-07-27.

import Combine
import Foundation
import SwiftUI

@Observable class PodViewModel: PodViewModelCallback {
    let windowId: UUID
    let data: RustPodViewModel

    var pods: LoadStatus<[Pod]> = .initial

    var toastWarning: String? = nil
    var toastError: String? = nil

    init(windowId: UUID) {
        self.windowId = windowId
        self.data = RustPodViewModel()
    }

    func getDataAndSetupWatcher(_ selectedCluster: ClusterId) async {
        await self.data.initializeModelWithResponder(responder: self)
        await self.data.fetchPods(selectedCluster: selectedCluster)
        await self.data.startWatcher(selectedCluster: selectedCluster)
    }

    func deletePods(selectedCluster: ClusterId, podIds: Set<Pod.ID>) async {
        if podIds.isEmpty {
            return
        }

        if podIds.count == 1 {
            return await self.data.deletePod(selectedCluster: selectedCluster, podId: podIds.first!)
        }

        await self.data.deletePods(selectedCluster: selectedCluster, podIds: Array(podIds))
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
