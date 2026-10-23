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
    @State private var isSplashPresented = true

    init() {
        Observability.start()
        RevenueCatConfiguration.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView(store: store)

                if isSplashPresented {
                    SplashView(isContentReady: store.hasLoadedContent) {
                        isSplashPresented = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .tint(Prep4JobTheme.indigo)
            .task {
                await store.load()
            }
        }
    }
}
