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
        Text(text)
    }
}

struct Previews_TabContentView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
