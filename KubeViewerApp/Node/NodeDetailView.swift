//
//  NodeDetailView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-06-19.
//

import Foundation
import SwiftUI

enum Section {
    case general
}

struct NodeDetailView: View {
    let geo: GeometryProxy
    let selectedNode: Node?

    @Namespace var namespace

    @State var generalIsExpanded = true

    @Binding var detailsWidth: CGFloat
    @Binding var detailsResized: Bool
    @Binding var isDetailsHover: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if case .some(let node) = self.selectedNode {
            ZStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    if generalIsExpanded {
                        HStack {
                            Text("General")
                                .font(.title)
                                .padding([.horizontal], 10)
                                .matchedGeometryEffect(id: Section.general, in: namespace)
                                .background(Color.gray.opacity(0))

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .transition(.opacity)
                                .padding(.trailing, 10)
                        }
                        .onTapGesture {
                            withAnimation {
                                generalIsExpanded.toggle()
                            }
                        }
                    }

                    CollapsibleList(
                        isExpanded: $generalIsExpanded,
                        content: {
                            HStack(alignment: .top) {
                                Text("Node Name").bold().textSelection(.enabled)
                                Spacer()
                                Text(node.name).textSelection(.enabled)
                            }
                            .padding(.horizontal, 20)
                            .onTapGesture {
                                withAnimation {
                                    generalIsExpanded.toggle()
                                }
                            }
                        },
                        label: {
                            if !generalIsExpanded {
                                Text("General")
                                    .font(.title)
                                    .padding(.horizontal, 15)
                                    .matchedGeometryEffect(id: Section.general, in: namespace)
                            }
                        }
                    )
                    .padding(.vertical, 20)
                    .if(self.colorScheme == .light) { view in
                        view.background(Color.white.opacity(0.6))
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
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
