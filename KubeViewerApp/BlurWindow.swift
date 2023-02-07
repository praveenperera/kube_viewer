//
//  BlurWindow.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-02-06.
//

import SwiftUI

struct BlurWindow: NSViewRepresentable {

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}
