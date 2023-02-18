import Foundation
import SwiftUI

extension AnyTransition {
    static func slideUpDown(_ height: CGFloat) -> AnyTransition {
        AnyTransition.modifier(
            active: SlideUpDown(offsetDirection: -1, height: height),
            identity: SlideUpDown(offsetDirection: 0, height: height))
    }

    static var slideUpDown: AnyTransition {
        AnyTransition.modifier(
            active: SlideUpDown(offsetDirection: -1, height: 250),
            identity: SlideUpDown(offsetDirection: 0, height: 250))
    }
}

struct SlideUpDown: ViewModifier {
    let offsetDirection: CGFloat
    let height: CGFloat

    func body(content: Content) -> some View {
        content.offset(y: offsetDirection * height).clipped()
    }
}
