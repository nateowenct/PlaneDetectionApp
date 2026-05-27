//
//  PlaneDetectionAppApp.swift
//  PlaneDetectionApp
//
//  Created by Nate Owen on 5/20/26.
//

import SwiftUI

@main
struct PlaneDetectionAppApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        
        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView(appState: appState)
        }
    }
}
