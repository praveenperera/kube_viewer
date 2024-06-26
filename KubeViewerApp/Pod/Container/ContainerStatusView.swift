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
        switch container.state {
        case let .some(containerState):
            PopoverWithDelayView(
                content: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stateColor)
                        .frame(width: 16)
                },
                popover: {
                    ContainerStatePopoverView(name: container.name, state: containerState)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                },
                delay: 100
            )

        case .none:
            EmptyView()
        }
    }
}

struct ContainerStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ContainerStatusView(container: containerPreview())
    }
}
