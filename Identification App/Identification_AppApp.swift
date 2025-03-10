//
//  Identification_AppApp.swift
//  Identification App
//
//  Created by Allen James Vinoy on 11/02/25.
//

import SwiftUI

// MARK: - App Entry Point
@main
struct Identification_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - AppDelegate Implementation
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Access SessionManager to initialize it at app launch
        _ = SessionManager.shared
        
        print("Session User ID: \(SessionManager.shared.sessionUserID)")
        
        return true
    }
}

class SessionManager {
    // Singleton instance
    static let shared = SessionManager()
    
    // Session user ID that persists for the entire app session
    private(set) var sessionUserID: String
    
    // Private initializer for singleton
    private init() {
        // Generate the user ID once when SessionManager is created
        sessionUserID = "user_\(UUID().uuidString)"
    }
    
    private func generateUniqueUserID() -> String {
        return "user_\(UUID().uuidString)"
    }
    
    // Optional: Regenerate user ID if needed (e.g., after logout)
    func regenerateSessionUserID() {
        sessionUserID = "user_\(UUID().uuidString)"
    }
}
