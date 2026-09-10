//
//  Prep4JobApp.swift
//  Prep4Job
//
//  Created by Renzo on 10/09/26.
//

import SwiftUI

@main
struct Prep4JobApp: App {
    @StateObject private var store = PrepStore()

    var body: some Scene {
        WindowGroup {
            RootTabView(store: store)
                .tint(Prep4JobTheme.indigo)
                .task {
                    await store.load()
                }
        }
    }
}
