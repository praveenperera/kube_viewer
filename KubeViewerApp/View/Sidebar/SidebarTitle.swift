//
//  SidebarTitle.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2/17/23.
//

import SwiftUI

struct SidebarTitle: View {
    var name: String

    var body: some View {
        Text(name)
            .foregroundColor(.secondary)
            .font(.system(size: 11, weight: .semibold))
    }
}

struct SidebarTitle_Previews: PreviewProvider {
    static var previews: some View {
        SidebarTitle(name: "General")
    }
}
