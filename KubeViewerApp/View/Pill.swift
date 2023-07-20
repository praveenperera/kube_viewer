//
//  Pill.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-07-20.
//

import SwiftUI

struct Pill<Content: View>: View {
    @ViewBuilder
    var content: Content

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            content
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(colorScheme == .light ? 0.05 : 0.1))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Spacer()
        }
    }
}

struct Pill_Previews: PreviewProvider {
    static var previews: some View {
        Pill { Text("key=value") }
    }
}
