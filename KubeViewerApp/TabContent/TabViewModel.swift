//
//  TabViewModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 1/24/23.
//

import Foundation
import SwiftUI

class TabViewModel: ObservableObject {
    @Published var tabs: [Int32];
    static var defaultTabs: [Int32] = [];
    
   
    init(tabs: [Int32] = TabViewModel.defaultTabs) {
        self.tabs = tabs
    }
}
