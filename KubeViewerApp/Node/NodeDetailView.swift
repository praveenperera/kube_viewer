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
                ScrollView {
                    VStack(alignment: .leading) {
                        // general
                        NodeDetailDropDown(title: "General", content: {
                            VStack {
                                HStack {
                                    Text("Node Name").bold()
                                    Spacer()
                                    Text(node.name)
                                        .textSelection(.enabled)
                                        .truncationMode(.tail)
                                        .lineLimit(1)
                                        .padding(.trailing, 15)
                                }
                                .padding(.bottom, 5)

                                HStack {
                                    Text("Created At").bold()
                                    Spacer()
                                    Text(node.createdAtTimestamp() ?? "").textSelection(.enabled)
                                }
                                .padding(.bottom, 5)

                                if !node.taints.isEmpty {
                                    HStack {
                                        Text("Taints").bold()
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            ForEach(node.taints, id: \.key) { taint in
                                                if let value = taint.value {
                                                    Text("\(taint.key)=\(value)").textSelection(.enabled)
                                                } else {
                                                    Text("\(taint.key)").textSelection(.enabled)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.bottom, 5)
                                }
                            }
                        })

                        // Labels
                        NodeDetailDropDown(title: "Labels", isExpanded: false, content: {
                            VStack(alignment: .leading) {
                                ForEach(node.labels.sorted(by: >), id: \.key) { key, value in
                                    HStack {
                                        Text("\(key)=\(value)").textSelection(.enabled)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.primary.opacity(colorScheme == .light ? 0.05 : 0.1))
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))

                                        Spacer()
                                    }
                                    // padding between pills
                                    .padding(.bottom, 2)
                                }
                            }
                        })
                    }
                    // VStack
                    .frame(maxWidth: self.detailsWidth)
                    .cornerRadius(4)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 20)
                }

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
