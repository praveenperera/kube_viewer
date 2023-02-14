//
//  ViewModel.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import Combine
import Foundation
import SwiftUI

class MainViewModel: ObservableObject {
    @Published var window: NSWindow?
    @Published var selectedMainTab: NSWindow?
    @RustPublished var selectedTab: TabId

    init() {
        self.selectedTab = defaultTabGroups.general.tabs[0].id
    }
}

struct Previews_MainViewModel_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
