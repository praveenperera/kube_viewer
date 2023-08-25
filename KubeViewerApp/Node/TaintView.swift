//
//  TaintView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-25.
//

import SwiftUI

struct TaintView: View {
    let taints: [Taint]
    @State private var isHovering: Bool = false

    var body: some View {
        Text(String(taints.count))
            .onHover { hovering in isHovering = hovering }
            .popover(isPresented: $isHovering) {
                ForEach(taints, id: \.hashValue) { taint in
                    VStack {
                        if taint.effect.isEmpty {
                            Text(taint.key).padding()
                        } else {
                            Text("\(taint.key)=\(taint.effect)")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
    }
}

struct TaintView_Previews: PreviewProvider {
    static var previews: some View {
        TaintView(taints: [])
    }
}
