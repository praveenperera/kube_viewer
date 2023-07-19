//
//  NodeDetailDropDown.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-07-19.
//

import SwiftUI

struct NodeDetailDropDown<Content: View>: View {
    var title: String

    @Environment(\.colorScheme) var colorScheme

    @State var isExpanded: Bool = true
    @Namespace var namespace

    @ViewBuilder var content: Content

    var body: some View {
        VStack {
            if isExpanded {
                HStack {
                    Text(title)
                        .font(.title)
                        .padding([.horizontal], 10)
                        .matchedGeometryEffect(id: title, in: namespace)
                        .background(Color.gray.opacity(0))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .transition(.opacity)
                        .padding(.trailing, 10)
                }
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            }

            CollapsibleList(
                isExpanded: $isExpanded,
                content: {
                    content
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }
                },
                label: {
                    if !isExpanded {
                        Text(title)
                            .font(.title)
                            .padding(.horizontal, 15)
                            .matchedGeometryEffect(id: title, in: namespace)
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
    }
}

// struct NodeDetailDropDown_Previews: PreviewProvider {
//    static var previews: some View {
//        NodeDetailDropDown()
//    }
// }
