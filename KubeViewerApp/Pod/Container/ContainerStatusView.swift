//
//  ContainerStatus.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-25.
//

import SwiftUI

struct ContainerStatusView: View {
    let container: Container

    var stateColor: Color {
        switch container.state {
        case .some(.running(data: _)):
            return Color.green
        case .some(.terminated(data: _)):
            return Color.gray
        case .none, .some(.waiting(data: _)):
            return Color.orange
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(stateColor)
            .frame(width: 16)
    }
}

struct ContainerStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ContainerStatusView()
    }
}
