//
//  Rosetta_WatcherApp.swift
//  Rosetta Watcher
//
//  Created by Mejdej on 24/06/2025.
//

import SwiftUI

@main
struct Rosetta_WatcherApp: App {
    @ObservedObject var model = ContentViewModel()
    
    var body: some Scene {
        MenuBarExtra(
            isInserted: true,
            content: {
                MenuBarContentView(model: model)
            },
            label:  {
                MenuBarLabelView(model: model)
            }
        )
    }
}

extension Binding: @retroactive @MainActor ExpressibleByBooleanLiteral where Value == Bool {
    public init(booleanLiteral value: Bool) {
        self = .constant(value)
    }
}
