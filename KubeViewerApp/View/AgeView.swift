//
//  AgeView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-03.
//

import SwiftUI

struct AgeView: View {
    let createdAt: Int64?
    let age: () -> String?

    var body: some View {
        if let timestamp = createdAt,
           let utc = unixToUtcString(unix: timestamp)
        {
            PopoverWithDelayView(content: {
                RelativeTimeView
            }, popover: {
                Text(utc)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
            })
        } else {
            RelativeTimeView
        }
    }

    @ViewBuilder
    var RelativeTimeView: some View {
        switch Date().timeIntervalSince1970 - Double(createdAt ?? 0) {
        case 0 ... 60:
            TimelineView(.periodic(from: Date(), by: 1)) { _ in
                Text(age() ?? "")
            }
        case 60 ... (60 * 60):
            TimelineView(.periodic(from: Date(), by: 60)) { _ in
                Text(age() ?? "")
            }
        default:
            Text(age() ?? "")
        }
    }
}

struct AgeView_Previews: PreviewProvider {
    static func age() -> String? {
        "6 seconds ago"
    }

    static var previews: some View {
        AgeView(createdAt: 1000000, age: age)
    }
}
