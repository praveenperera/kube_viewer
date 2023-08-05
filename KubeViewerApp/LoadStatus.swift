//
//  LoadStatus.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-02.
//

import Foundation

enum LoadStatus<T: Equatable>: Equatable {
    case initial,
         loading,
         error(error: String),
         loaded(data: T)
}
