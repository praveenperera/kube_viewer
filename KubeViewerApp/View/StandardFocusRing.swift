//
//  StandardFocusRing.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2/24/23.
//

import SwiftUI

struct StandardFocusRing: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .stroke(.blue.opacity(0.45), lineWidth: 3.5).padding(.horizontal, 2)
    }
}

struct StandardFocusRing_Previews: PreviewProvider {
    static var previews: some View {
        StandardFocusRing()
    }
}
