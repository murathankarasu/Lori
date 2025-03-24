//
//  ContentView.swift
//  Lori
//
//  Created by Murathan Karasu on 18.03.2025.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isLoggedIn = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                FeedView(isLoggedIn: $isLoggedIn)
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, user in
                isLoggedIn = user != nil
            }
        }
    }
}

#Preview {
    ContentView()
}
