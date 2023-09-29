//
//  NamespacePicker.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-09-29.
//

import SwiftUI

struct NamespacePicker: View {
    let namespaces: [String]
    @State var selected: String

    init(namespaces: [String], selected: String) {
        // add "All" option
        var namespaces = namespaces
        namespaces.insert("All", at: 0)

        self.namespaces = namespaces
        self.selected = selected
    }

    var body: some View {
        Picker("", selection: $selected) {
            ForEach(namespaces, id: \.self) { namespace in
                Text(namespace)
            }
        }
        .pickerStyle(.menu)
        .onChange(of: selected) {
            // #TODO: send to selected namespace to model
        }
    }
}

#Preview("NamespacePicker") {
    let namespaces = ["default", "devops", "praveen", "growth", "marketing"]

    let view = HStack {
        NamespacePicker(namespaces: namespaces, selected: "All")
            .padding()
    }
    .frame(minWidth: 250, minHeight: 250)

    return view
}
