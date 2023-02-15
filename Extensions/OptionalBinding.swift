//
//  OptionalBinding.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-02-14.
//

import Foundation
import SwiftUI

func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
