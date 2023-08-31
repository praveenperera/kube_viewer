//
//  PodPhaseView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-30.
//

import SwiftUI

struct PodPhaseView: View {
    let phase: Phase
    let isSelected: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch phase {
        case .failed:
            Text("Failed").foregroundColor(isSelected ? Color.primary : Color.red)
        case .succeeded:
            Text("Succeeded").foregroundColor(isSelected ? Color.primary : Color.green)
                .if(self.colorScheme == .light) { view in
                    view.brightness(-0.10)
                }
        case .pending: Text("Pending")
        case .running:
            Text("Running").foregroundColor(isSelected ? Color.primary : Color.green)
                .if(self.colorScheme == .light) { view in
                    view.brightness(-0.15)
                }
        case .unknown(rawValue: let rawValue):
            Text(rawValue)
        }
    }
}

struct PodPhaseView_Previews: PreviewProvider {
    static var previews: some View {
        PodPhaseView(phase: Phase.running, isSelected: false)
    }
}
