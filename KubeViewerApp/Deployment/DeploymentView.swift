//
//  DeploymentView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-09.
//

import SwiftUI

struct Item: Identifiable {
    var id: String
    var value: String
}

struct DeploymentView: View {
    @State private var items = [Item(id: "A", value: "A"), Item(id: "B", value: "B")]

    @State private var selectedItems = Set<Item.ID>()

    var body: some View {
        Table(items, selection: $selectedItems) {
            TableColumn("Name", value: \.value)
        }
    }
}

struct DeploymentView_Previews: PreviewProvider {
    static var previews: some View {
        DeploymentView()
    }
}
