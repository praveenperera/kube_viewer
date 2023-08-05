//
//  PodDetailView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-06-19.
//

import Foundation
import SwiftUI

struct PodDetailView: View {
    let geo: GeometryProxy
    let selectedPod: Pod?

    @Binding var detailsWidth: CGFloat
    @Binding var detailsResized: Bool
    @Binding var isDetailsHover: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if case .some(let pod) = self.selectedPod {
            ZStack(alignment: .leading) {
                ScrollView {
                    VStack(alignment: .leading) {}
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

struct PodDetailsView_Previews: PreviewProvider {
    static var podModel = RustPodViewModel.preview()

    static var previews: some View {
        GeometryReader { geo in
            PodDetailView(geo: geo,
                          selectedPod: podPreview(),
                          detailsWidth: Binding.constant(300),
                          detailsResized: Binding.constant(true),
                          isDetailsHover: Binding.constant(false))
        }
    }
}
