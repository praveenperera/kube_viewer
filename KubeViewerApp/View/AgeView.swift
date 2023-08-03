//
//  AgeView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-03.
//

import SwiftUI

struct AgeView: View {
    let createdAt: Int64?
    let age: String?

    var body: some View {
        Text(age ?? "")
    }
}

struct AgeView_Previews: PreviewProvider {
    static var previews: some View {
        AgeView(createdAt: 1000000, age: "6 Seconds ago")
    }
}
