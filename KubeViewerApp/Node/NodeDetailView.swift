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
                        // General
                        NodeDetailDropDown(title: "General", content: {
                            VStack {
                                HStack {
                                    Text("Node Name").bold()
                                    Spacer()
                                    Text(node.name)
                                        .textSelection(.enabled)
                                        .truncationMode(.tail)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .padding(.leading, 30)
                                }
                                .padding(.bottom, 2)

                                HStack {
                                    Text("Created At").bold()
                                    Spacer()
                                    Text(node.createdAtTimestamp() ?? "")
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .lineLimit(1)
                                        .padding(.leading, 30)
                                }
                                .padding(.bottom, 2)

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
                                    .padding(.bottom, 2)
                                }
                            }
                        })

                        // Addresses
                        NodeDetailDropDown(title: "Addresses") {
                            VStack(alignment: .leading) {
                                ForEach(node.addresses, id: \.nodeType) { address in
                                    HStack {
                                        Text(address.nodeType).bold()
                                        Spacer()
                                        Text(address.address)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .padding(.leading, 30)
                                    }
                                    .padding(.bottom, 2)
                                }
                            }
                        }

                        // Labels
                        NodeDetailDropDown(title: "Labels", isExpanded: false) {
                            VStack(alignment: .leading) {
                                ForEach(node.labels.sorted(by: >), id: \.key) { key, value in
                                    Pill {
                                        Text("\(key)=\(value)").textSelection(.enabled)
                                    }
                                    .padding(.bottom, 2)
                                }
                            }
                        }

                        // Annotations
                        NodeDetailDropDown(title: "Annotations", isExpanded: false) {
                            VStack(alignment: .leading) {
                                ForEach(node.annotations.sorted(by: >), id: \.key) { key, value in
                                    Pill {
                                        Text("\(key)=\(value)").textSelection(.enabled)
                                    }
                                    .padding(.bottom, 2)
                                }
                            }
                        }

                        // OS Info
                        NodeDetailDropDown(title: "OS") {
                            VStack(alignment: .leading) {
                                if let os = node.os {
                                    HStack {
                                        Text("OS").bold()
                                        Spacer()
                                        Text(os)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .padding(.leading, 30)
                                    }
                                    .padding(.bottom, 2)
                                }

                                if let osImage = node.osImage {
                                    HStack {
                                        Text("OS Image").bold()
                                        Spacer()
                                        Text(osImage)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .padding(.leading, 30)
                                    }
                                    .padding(.bottom, 2)
                                }

                                if let arch = node.arch {
                                    HStack {
                                        Text("Arch").bold()
                                        Spacer()
                                        Text(arch)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .padding(.leading, 30)
                                    }
                                    .padding(.bottom, 2)
                                }

                                if let containerRuntime = node.containerRuntime {
                                    HStack {
                                        Text("Container Runtime").bold()
                                        Spacer()
                                        Text(containerRuntime)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .padding(.leading, 30)
                                    }
                                    .padding(.bottom, 2)
                                }

                                if let kernelVersion = node.kernelVersion {
                                    HStack {
                                        Text("Kernel Version").bold()
                                        Spacer()
                                        Text(kernelVersion)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .padding(.leading, 30)
                                    }
                                    .padding(.bottom, 2)
                                }

                                if let kubeletVersion = node.kubeletVersion {
                                    HStack {
                                        Text("Kubelet Version").bold()
                                        Spacer()
                                        Text(kubeletVersion)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .padding(.leading, 30)
                                    }
                                    .padding(.bottom, 2)
                                }
                            }
                        }
                    }
                    // end VStack
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
