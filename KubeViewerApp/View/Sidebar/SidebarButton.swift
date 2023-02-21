//
//  SidebarButton.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2/17/23.
//

import SwiftUI

struct SidebarButton: View {
    var tab: Tab
    @Binding var selectedTab: TabId
    @State private var isHover = false

    var tabIsSelected: Bool {
        selectedTab == tab.id
    }

    var body: some View {
        HStack {
            Button(action: { selectedTab = tab.id }) {
                Label {
                    Text(tab.name)
                        .foregroundColor(tabIsSelected ? Color.white : Color.primary)
                } icon: {
                    Image(systemName: tab.icon)
                        .foregroundColor(tabIsSelected ? Color.white : Color.accentColor)
                }
            }.buttonStyle(.plain).padding(.leading, 10)
                .if(isHover && !tabIsSelected) { view in
                    view.scaleEffect(1.015)
                }.animation(.default, value: isHover)
            Spacer()
        }
        .padding([.top, .bottom], 5)
        .padding(.trailing, 15)
        .frame(maxWidth: .infinity)
        .if(tabIsSelected) { view in
            view.background(Color.accentColor.opacity(0.90))
                .background(.ultraThinMaterial)
        }
        .if(isHover && !tabIsSelected) { view in
            view.background(Color.secondary.opacity(0.25))
                .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring()) {
                self.selectedTab = tab.id
            }
        }
        .whenHovered { hovering in
            withAnimation {
                self.isHover = hovering
            }
        }
    }
}

struct SidebarButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SidebarButton(tab: Tab(id: .cluster, icon: "helm", name: "Helm"), selectedTab: Binding.constant(.cluster))
            SidebarButton(tab: Tab(id: .cluster, icon: "helm", name: "Helm"), selectedTab: Binding.constant(.charts))
        }.frame(width: 150)
            .padding(20)
    }
}
