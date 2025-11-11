//
//  SC40_V3App.swift
//  SC40-V3
//
//  Created by David O'Connell on 05/11/2025.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
import AVFoundation
#endif

@main
struct SC40_V3App: App {
    @StateObject private var audioSessionManager = AudioSessionManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("📱 ContentView APPEARED - iOS app is running")
                }
        }
    }
}

#if canImport(UIKit)
/// Manages audio session configuration to prevent AudioGraph crashes
@MainActor
final class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()
    
    // Required for ObservableObject conformance
    let objectWillChange = ObservableObjectPublisher()
    
    private init() {
        print("📱📱📱 iOS APP STARTING 📱📱📱")
        print("📱 AudioSessionManager INITIALIZING")
        print("📱 Device: \(UIDevice.current.name)")
        print("📱 iOS Version: \(UIDevice.current.systemVersion)")
        
        // CRASH FIX: Initialize audio session early to prevent AudioGraph crashes
        configureAudioSession()
    }
    
    /// Configure audio session to prevent AudioGraph crashes
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Set category to allow audio playback and mixing with other apps
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            
            // Activate the audio session
            try audioSession.setActive(true, options: [])
            
            print("✅ Audio session configured successfully")
        } catch {
            print("⚠️ Audio session configuration failed: \(error.localizedDescription)")
            print("   This is non-fatal - app will continue without audio")
        }
    }
}
#else
// Dummy implementation for non-iOS platforms
@MainActor
final class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()
    let objectWillChange = ObservableObjectPublisher()
    private init() {}
}
#endif
