//
//  SearchField.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2/16/23.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @EnvironmentObject var mainViewModel: MainViewModel
    @FocusState private var isFocused: Bool

    var isEditing: Bool {
        text != ""
    }

    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .padding(.vertical, 7)
                .padding(.horizontal, 35)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(4)
                .overlay {
                    if isFocused {
                        StandardFocusRing()
                    }
                }
                .overlay {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.primary)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 11)
                            .opacity(0.9)

                        // x button shown if editing
                        Button(action: {
                            withAnimation(.spring()) {
                                self.text = ""
                                self.isFocused = false
                            }
                        }) {
                            Image(systemName: "multiply.circle.fill")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 10)
                        .transition(.scale)
                        .keyboardShortcut(.escape, modifiers: [])
                        .opacity(isEditing ? 100 : 0)
                    }
                }
                .onChange(of: mainViewModel.currentFocusRegion) { newFocus in
                    if newFocus == .sidebarSearch {
                        isFocused = true
                    }
                }
                .onChange(of: isFocused) { newFocus in
                    if newFocus && mainViewModel.currentFocusRegion != .sidebarSearch {
                        mainViewModel.currentFocusRegion = .sidebarSearch
                    }
                }
                .background(KeyAwareView(onEvent: mainViewModel.data.handleKeyInput))
        }
    }
}

struct SearchField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SearchBar(text: Binding.constant("search"))
        }.frame(width: 250).padding(20)
    }
}