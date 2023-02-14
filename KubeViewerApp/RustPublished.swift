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
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, RustPublished<Value>>
    ) -> Value {
        get {
            return object[keyPath: storageKeyPath].innervalue
        }
        set {
            object[keyPath: storageKeyPath].innervalue = newValue
            object[keyPath: storageKeyPath].publisher.send(newValue)
            (object.objectWillChange as? ObservableObjectPublisher)?.send()
        }
    }

    private let publisher = PassthroughSubject<Value, Never>()
    private var innervalue: Value

    init(wrappedValue value: Value) {
        self.innervalue = value
    }

    @available(*, unavailable,
               message: "@Published can only be applied to classes")
    var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    var projectedValue: AnyPublisher<Value, Never> {
        return self.publisher.eraseToAnyPublisher()
    }

    private var asPublisher: AnyPublisher<Value, Never> {
        return self.publisher.eraseToAnyPublisher()
    }
}

extension RustPublished: Publisher {
    typealias Output = Value
    typealias Failure = Never

    func receive<S>(subscriber: S) where S: Subscriber,
        Failure == S.Failure,
        Output == S.Input
    {
        self.asPublisher.receive(subscriber: subscriber)
    }
}