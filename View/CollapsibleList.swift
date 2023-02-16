//
//  CollapseableList.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2/16/23.
//

import SwiftUI

struct CollapsibleList<Content: View, Label: View>: View {
    @Binding var isExpanded: Bool
    @State var isHovering = false

    @ViewBuilder var content: Content
    @ViewBuilder var label: Label

    var body: some View {
        VStack {
            Button {
                withAnimation {
                    self.isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    self.label.animation(nil, value: self.isExpanded)
                    Spacer()

                    if isHovering {
                        Image(systemName: self.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .animation(nil, value: self.isExpanded)
                            .animation(.easeIn, value: isHovering)
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

            if self.isExpanded {
                self.content.padding(.leading, -5)
            }
        }
    }
}

struct CollapsibleList_Previews: PreviewProvider {
    static var previews: some View {
        CollapsibleList(isExpanded: .constant(true)) {
            Text("Hello")
        } label: {
            Text("Label")
        }
    }
}
