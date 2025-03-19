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
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}
