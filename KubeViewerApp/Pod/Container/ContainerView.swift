//
//  ContainerView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-25.
//

import SwiftUI

struct ContainerView: View {
    let containers: [Container]

    var body: some View {
        HStack {
            Spacer()
            ForEach(containers) { ContainerStatusView(container: $0) }
            Spacer()
        }
    }
}

struct ContainerView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            ContainerView(containers: [containersPreview()])
        }
    }
}
