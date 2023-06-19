//
//  NodeDetailView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-06-19.
//

import Foundation
import SwiftUI

struct NodeDetailView: View {
    let geo: GeometryProxy
    let selectedNode: Node?

    @Binding var detailsWidth: CGFloat
    @Binding var detailsResized: Bool
    @Binding var isDetailsHover: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if case .some(let node) = self.selectedNode {
            ZStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    CollapsibleList(
                        content: {
                            HStack {
                                Text("Node Name")
                                Text(node.name)
                                Spacer()
                            }
                            .padding(.leading, 20)
                        },
                        label: {
                            Text("General")
                                .font(.title)
                                .padding(.horizontal, 10)
                        }
                    )
                    .padding(.vertical, 25)
                    .if(self.colorScheme == .light) { view in
                        view.background(Color.white.opacity(0.6))
                    }
                    .background(.ultraThinMaterial)
                }
                .background(.ultraThickMaterial)
                .frame(maxWidth: self.detailsWidth)
                .cornerRadius(4)
                .padding(.horizontal, 10)

                // drag to resize handle
                Color.primary
                    .opacity(0.001)
                    .frame(maxWidth: 5, maxHeight: .infinity)
                    .shadow(radius: 2)
                    .offset(x: -8)
                    .onHover(perform: { hovering in
                        self.isDetailsHover = hovering
                        if self.isDetailsHover {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    })
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                DispatchQueue.main.async {
                                    let detailsWidth = min(geo.size.width - 300, self.detailsWidth + (drag.translation.width * -1))
                                    self.detailsWidth = max(detailsWidth, 200)
                                    self.detailsResized = true
                                }
                            }
                    )
            }
        }
    }
}

struct NodeDetailsView_Previews: PreviewProvider {
    static var nodeModel = RustNodeViewModel.preview(windowId: UUID().uuidString)

    static var previews: some View {
        GeometryReader { geo in
            NodeDetailView(geo: geo,
                           selectedNode: nodePreview(),
                           detailsWidth: Binding.constant(300),
                           detailsResized: Binding.constant(true),
                           isDetailsHover: Binding.constant(false))
        }
    }
}
