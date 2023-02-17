import Foundation
import SwiftUI

extension AnyTransition {
    static func slideUpDown(_ height: CGFloat) -> AnyTransition {
        AnyTransition.modifier(
            active: SlideUpDown(offset: -1, height: height),
            identity: SlideUpDown(offset: 0, height: height))
    }

    static var slideUpDown: AnyTransition {
        AnyTransition.modifier(
            active: SlideUpDown(offset: -1, height: 250),
            identity: SlideUpDown(offset: 0, height: 250))
    }
}

struct SlideUpDown: ViewModifier {
    let offset: CGFloat
    let height: CGFloat

    func body(content: Content) -> some View {
        content.offset(y: offset * height).clipped()
    }
}
