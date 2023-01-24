//
//  ContentView.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

struct ContentView: View {
   
    @StateObject private var model = ViewModel()
    
    var body: some View {
        Text("hi")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
