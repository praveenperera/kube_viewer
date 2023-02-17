//
//  TabContentView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 1/24/23.
//

import Foundation
import SwiftUI

struct TabContentView: View {
    var text: String

    var body: some View {
        HStack {
            Text(text)
        }
//        .toolbar {
//            ToolbarItemGroup {
//                Image(systemName: "gear")
//            }
//            ToolbarItemGroup {
//                Image(systemName: "server.rack")
//            }
//            ToolbarItem {
//                Picker("Sort", selection: Binding.constant("title")) {
//                    Text("Title").tag("title")
//                    Text("Score")
//                    Text("Last Updated")
//                    Text("Last Added")
//                }
//            }
//        }
    }
}

struct Previews_TabContentView_Previews: PreviewProvider {
    static var previews: some View {
        TabContentView(text: "Hello")
    }
}
