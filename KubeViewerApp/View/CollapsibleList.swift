//
//  CollapseableList.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2/16/23.
//

import SwiftUI

struct CollapsibleList<Content: View, Label: View>: View {
    var isExpanded: Binding<Bool>? = nil
    @State var isHovering = false
    @State var startExpanded: Bool = true

    @ViewBuilder
    var content: Content

    @ViewBuilder
    var label: Label

    func toggleExpand() {
        if let isExpanded = isExpanded {
            return isExpanded.wrappedValue.toggle()
        } else {
            return self.startExpanded.toggle()
        }
    }

    var expanded: Bool {
        self.isExpanded?.wrappedValue ?? self.startExpanded
    }

    var body: some View {
        VStack {
            Button {
                withAnimation {
                    self.toggleExpand()
                }

            } label: {
                HStack(alignment: .firstTextBaseline) {
                    self.label.animation(nil, value: self.expanded)
                    Spacer()

                    if self.isHovering {
                        Image(systemName: self.expanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .animation(nil, value: self.expanded)
                            .animation(.easeIn, value: self.isHovering)
                            .transition(.opacity)
                            .padding(.trailing, 10)
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

            if self.expanded {
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
