//
//  PodDeleteConfirmMessage.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-31.
//

import SwiftUI

struct PodDeleteConfirmMessage: View {
    let podIds: Set<Pod.ID>
    let maxToShow = 50

    var seperator: String {
        "\n"
    }

    var body: some View {
        switch podIds.count {
        case 0:
            EmptyView()
        case 1:
            Text(podIds.first ?? "").bold()
        case 1 ... maxToShow:
            Text(podIds.joined(separator: seperator))
        case maxToShow ... Int.max:
            let showingOnes = Array(podIds)[0 ... maxToShow].joined(separator: seperator)
            let podsLeft = podIds.count - maxToShow

            Text("\(showingOnes)\n\n and \(podsLeft) more...")
        default:
            Text(podIds.joined(separator: seperator)).bold()
        }
    }
}

struct PodDeleteConfirmMessage_Previews: PreviewProvider {
    static var previews: some View {
        PodDeleteConfirmMessage(podIds: [podPreview().id])
    }
}
