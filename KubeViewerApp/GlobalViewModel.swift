//
//  GlobalViewModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 3/16/23.
//

import Combine
import Foundation
import SwiftUI

class GlobalViewModel: ObservableObject, GlobalViewModelCallback {
    var data: RustGlobalViewModel
    @RustPublished var clusters: [ClusterId: Cluster]

    init() {
        self.data = RustGlobalViewModel()

        self.clusters = self.data.clusters()
        self._clusters.getter = self.data.clusters
        DispatchQueue.main.async { self.setupCallback() }
    }

    private func setupCallback() {
        self.data.addCallbackListener(responder: self)
    }

    func callback(msg: GlobalViewModelMessage) {
        Task {
            await MainActor.run {
                switch msg {
                case .clustersLoaded:
                    print("[swift] clusters loaded")
                    self.clusters = self.data.clusters()

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
