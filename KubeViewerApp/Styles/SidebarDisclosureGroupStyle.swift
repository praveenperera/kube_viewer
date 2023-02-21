//
//  SidebarStyle.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2/17/23.
//

import SwiftUI

struct SidebarDisclosureGroupStyle: DisclosureGroupStyle {
    @State private var isHovering = false
    @State private var headerLocation: CGFloat = 0
    @State private var contentHeight: CGFloat = 0

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    configuration.label.animation(nil, value: configuration.isExpanded)
                    Spacer()

                    if isHovering {
                        Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .animation(nil, value: configuration.isExpanded)
                            .animation(.easeIn, value: self.isHovering)
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 0)
                .contentShape(Rectangle())
            }
            .padding(.bottom, 0)
            .buttonStyle(.plain)
            .onHover { isHovering in
                withAnimation {
                    self.isHovering = isHovering
                }
            }

            if configuration.isExpanded {
                configuration.content.padding(.leading, -5)
                    .transition(
                        .slideUpDown(contentHeight).combined(with: .opacity)
                    )
                    .readSize { size in contentHeight = size.height }
            }
        }
    }
}
