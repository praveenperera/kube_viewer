//
//  PopoverWithDelayView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-25.
//

import SwiftUI

struct PopoverWithDelayView<Content: View, Popover: View>: View {
    @State private var hoverTask: Task<Void, Error>?
    @State private var isHovering: Bool = false

    let delay: Double
    let content: Content
    let popover: Popover

    init(content: () -> Content, popover: () -> Popover, delay: Double? = nil) {
        self.content = content()
        self.popover = popover()
        self.delay = delay ?? 800

        self.hoverTask = nil
        self.isHovering = false
    }

    var body: some View {
        content
            .onHover { hovering in
                withAnimation {
                    if hovering {
                        hoverTask?.cancel()
                        hoverTask = Task {
                            try await Task.sleep(ms: delay)
                            isHovering = true
                        }
                    } else {
                        hoverTask?.cancel()
                        isHovering = hovering
                    }
                }
            }
            .popover(isPresented: $isHovering) {
                popover
            }
    }
}

// struct PopoverWithDelayView_Previews: PreviewProvider {
//    static var previews: some View {
//        PopoverWithDelayView()
//    }
// }
