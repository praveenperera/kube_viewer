//
//  GlobalViewModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 3/16/23.
//

import Combine
import Foundation
import SwiftUI

@Observable class GlobalViewModel: GlobalViewModelCallback {
    let data: RustGlobalViewModel
    var clusters: [ClusterId: Cluster]

    init() {
        self.data = RustGlobalViewModel()
        self.clusters = self.data.clusters()

        DispatchQueue.main.async { self.setupCallback() }
    }

    private func setupCallback() {
        Task {
            await self.data.addCallbackListener(responder: self)
        }
    }

    func callback(message: GlobalViewModelMessage) {
        Task {
            await MainActor.run {
                switch message {
                    case .refreshClusters:
                        print("[swift] refreshing cluster list")
                        self.clusters = self.data.clusters()

                    case let .clustersLoaded(clusters: clusters):
                        print("[swift] clusters loaded")
                        self.clusters = clusters

                    case .loadingClient:
                        // TODO: toast to show cluster is loading
                        ()

                    case .clientLoadError:
                        //  TODO: show toast with error
                        ()

                    case .clientLoaded:
                        print("[swift] client loaded")
                }
            }
        }
    }
}

extension Cluster: Identifiable {}

extension Cluster {
    func name() -> String {
        return self.nickname ?? self.id.rawValue
    }
}
