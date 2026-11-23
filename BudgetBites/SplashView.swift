//
//  SplashView.swift
//  BudgetBites
//
//  Created by Joshua Daramola on 26/03/2026.
//

import SwiftUI

// SplashView provides an initial entry point into the app, helping create a clear and structured user flow
// before transitioning into the main interface.
struct SplashView: View {
    // I use a binding here so this view can control when the app transitions to the main content.
    @Binding var hasStarted: Bool

    // The layout is structured to guide the user visually from branding to the main action.
    var body: some View {
        // A vertical layout is used to centre content and create a clean, focused entry screen.
        VStack(spacing: 24) {
            Spacer()

            // The logo reinforces branding and gives the app a more polished first impression.
            Image("AppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            // The app name is emphasised to clearly identify the application to the user.
            Text("BudgetBites")
                .font(.largeTitle)
                .fontWeight(.bold)

            // The tagline communicates the purpose of the app in a simple and immediate way.
            Text("Smart grocery budgeting made simple")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Spacer()

            // This button acts as the main call-to-action, allowing the user to enter the app.
            Button {
                // Updating this state triggers the transition from the splash screen to the main app.
                hasStarted = true
            } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    SplashView(hasStarted: .constant(false))
}
