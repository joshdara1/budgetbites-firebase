//
//  BudgetBitesApp.swift
//  BudgetBites
//
//  Created by Joshua Daramola on 24/03/2026.
//

import SwiftUI
import Firebase

@main
struct BudgetBitesApp: App {
    init() {
        FirebaseApp.configure()
    }

    // Controls whether the splash screen or main app is shown.
    @State private var hasStarted = false

    // Switches between SplashView and ContentView based on user interaction.
    var body: some Scene {
        WindowGroup {
            if hasStarted {
                ContentView()
            } else {
                SplashView(hasStarted: $hasStarted)
            }
        }
    }
}
