//
//  AppState.swift
//  PlaneDetectionApp
//
//  Created by Claude on 5/20/26.
//

import SwiftUI
import RealityKit

/// Main application state for managing placement mode and content
@Observable
class AppState {
    var placementMode: PlacementMode = .image
    var selectedImage: UIImage?
    var selectedModelName: String?
    var activePlacement: Entity?
    var showPhotoPicker = false
    var showModelPicker = false

    // Available models in the app
    let availableModels = ["tennis_court_with_mini_golf"]

    // Scale and plane dimensions for pinch-to-zoom
    var currentScale: Float = 0.75  // Start at 75% of plane
    var planeDimensions: (width: Float, height: Float)?
    var modelBaseScale: SIMD3<Float>?  // Store base scale for model scaling

    // Rotation for models
    var currentRotation: Angle = .zero  // Current rotation angle

    /// Remove the currently placed content
    func removeActivePlacement() {
        activePlacement?.removeFromParent()
        activePlacement = nil
        currentScale = 0.75  // Reset scale
        planeDimensions = nil
        modelBaseScale = nil
        currentRotation = .zero  // Reset rotation
    }

    /// Check if placement is allowed (no active placement exists)
    var canPlace: Bool {
        activePlacement == nil
    }

    /// Check if content is ready to place based on mode
    var hasContentSelected: Bool {
        switch placementMode {
        case .image:
            return selectedImage != nil
        case .model:
            return selectedModelName != nil
        }
    }
}
