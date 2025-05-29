//
//  LorienApp.swift
//  Lorien
//
//  Created by Murathan on 23.05.2025.
//
import SwiftUI
import FirebaseCore

@main
struct LorienApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Uygulamayı sürekli karanlık temada tut
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = .dark
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(.dark)
        }
    }
}

