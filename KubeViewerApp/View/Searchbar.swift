//
//  SearchField.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2/16/23.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @EnvironmentObject var keyHandlerModel: KeyHandlerModel
    @FocusState private var isFocused: Bool

    @State private var isLoaded = false
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
                    if isLoaded && isFocused {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.blue.opacity(0.45), lineWidth: 3.5).padding(.horizontal, 2)
                    }
                }
                .overlay {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.primary)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 11)
                            .opacity(0.9)

                        if isEditing {
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
                        }
                    }
                }
                .keyboardShortcut(.escape)
                .onChange(of: keyHandlerModel.focusRegion) { newFocus in
                    if newFocus == .sidebarSearch {
                        isFocused = true
                    }
                }
                .background(KeyAwareView(onEvent: { key in
                    debugPrint("key down in search", key)

                    switch key {
                    case .tab:
                        debugPrint("tab pressed")
                        keyHandlerModel.focusRegion = .sidebarSearch
                    default:
                        ()
                    }

                    return true
                }))
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
