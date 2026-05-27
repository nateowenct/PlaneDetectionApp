//
//  ContentView.swift
//  PlaneDetectionApp
//
//  Created by Nate Owen on 5/20/26.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(AppState.self) private var appState
    @State private var immersiveSpaceIsShown = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Plane Detection App")
                .font(.largeTitle)
                .padding()

            VStack(spacing: 20) {
                ControlsView(appState: appState)

                Button(action: {
                    Task {
                        if immersiveSpaceIsShown {
                            await dismissImmersiveSpace()
                            immersiveSpaceIsShown = false
                        } else {
                            await openImmersiveSpace(id: "ImmersiveSpace")
                            immersiveSpaceIsShown = true
                        }
                    }
                }) {
                    Text(immersiveSpaceIsShown ? "Exit AR Mode" : "Enter AR Mode")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(immersiveSpaceIsShown ? .red : .blue)

                // Show instruction when in AR mode with content selected
                if immersiveSpaceIsShown && appState.hasContentSelected && appState.canPlace {
                    Text(appState.placementMode == .image ? "Select a plane to place your picture" : "Select a plane to place your model")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(width: 400)
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppState())
}
