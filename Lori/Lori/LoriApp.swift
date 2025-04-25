//
//  LoriApp.swift
//  Lori
//
//  Created by Murathan Karasu on 18.03.2025.
//
import SwiftUI
import FirebaseCore

@main
struct LoriApp: App {
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

