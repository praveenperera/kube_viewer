//
//  RustPublished.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-02-13.
//

import Combine
import Foundation

@propertyWrapper
struct RustPublished<Value> {
    private let publisher = PassthroughSubject<Value, Never>()
    private var value: Value

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
        get {
            self.value
        }
        set {
            self.value = newValue
            self.publisher.send(self.value)
        }
    }

    var projectedValue: AnyPublisher<Value, Never> {
        return self.publisher.eraseToAnyPublisher()
    }
}
