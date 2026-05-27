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

    let availableModels = ["tennis_court_with_mini_golf"]

    var currentScale: Float = 0.75
    var planeDimensions: (width: Float, height: Float)?
    var modelBaseScale: SIMD3<Float>?

    var currentRotation: Angle = .zero

    func removeActivePlacement() {
        activePlacement?.removeFromParent()
        activePlacement = nil
        currentScale = 0.75
        planeDimensions = nil
        modelBaseScale = nil
        currentRotation = .zero
    }

    var canPlace: Bool {
        activePlacement == nil
    }

    var hasContentSelected: Bool {
        switch placementMode {
        case .image:
            return selectedImage != nil
        case .model:
            return selectedModelName != nil
        }
    }
}
