//
//  AppStateTests.swift
//  PlaneDetectionAppTests
//
//  Created by Claude on 5/20/26.
//

import Testing
import RealityKit
@testable import PlaneDetectionApp

@Suite("AppState Tests")
struct AppStateTests {
    
    @Test("Initial state has no active placement")
    func initialState() {
        let appState = AppState()
        
        #expect(appState.activePlacement == nil)
        #expect(appState.canPlace == true)
        #expect(appState.placementMode == .image)
        #expect(appState.selectedImage == nil)
    }
    
    @Test("Can place when no active placement")
    func canPlaceWhenEmpty() {
        let appState = AppState()
        
        #expect(appState.canPlace == true)
    }
    
    @Test("Cannot place when active placement exists")
    func cannotPlaceWithActivePlacement() {
        let appState = AppState()
        
        // Simulate placement
        let anchor = AnchorEntity()
        appState.activePlacement = anchor
        
        #expect(appState.canPlace == false)
    }
    
    @Test("Remove active placement clears reference")
    func removeActivePlacement() {
        let appState = AppState()
        
        // Add placement
        let anchor = AnchorEntity()
        appState.activePlacement = anchor
        
        #expect(appState.activePlacement != nil)
        #expect(appState.canPlace == false)
        
        // Remove placement
        appState.removeActivePlacement()
        
        #expect(appState.activePlacement == nil)
        #expect(appState.canPlace == true)
    }
    
    @Test("Mode switching updates correctly")
    func modeSwitching() {
        let appState = AppState()
        
        #expect(appState.placementMode == .image)
        
        appState.placementMode = .model
        #expect(appState.placementMode == .model)
        
        appState.placementMode = .image
        #expect(appState.placementMode == .image)
    }
    
    @Test("Single placement enforcement")
    func singlePlacementEnforcement() {
        let appState = AppState()
        
        // First placement allowed
        #expect(appState.canPlace == true)
        
        let firstAnchor = AnchorEntity()
        appState.activePlacement = firstAnchor
        
        // Second placement blocked
        #expect(appState.canPlace == false)
        
        // Remove first placement
        appState.removeActivePlacement()
        
        // New placement allowed
        #expect(appState.canPlace == true)
    }
}
