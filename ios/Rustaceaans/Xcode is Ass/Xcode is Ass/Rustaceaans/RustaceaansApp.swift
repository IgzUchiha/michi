//
//  RustaceaansApp.swift
//  Rustaceaans
//
//  Created by Igmer Castillo on 10/11/25.
//

import SwiftUI

@main
struct RustaceaansApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var walletManager = WalletManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(walletManager)
        }
    }
}
