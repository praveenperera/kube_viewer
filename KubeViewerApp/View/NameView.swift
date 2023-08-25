//
//  NameView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-25.
//

import SwiftUI

struct NameView: View {
    let name: String
    let delay: Double

    init(name: String, delay: Double? = nil) {
        self.name = name
        self.delay = delay ?? 800
    }

    var body: some View {
        PopoverWithDelayView(content: {
            Text(name)
        }, popover: {
            Text(name)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
        }, delay: delay)
    }
}

struct NameView_Previews: PreviewProvider {
    static var previews: some View {
        NameView(name: "Test Name")
    }
}
