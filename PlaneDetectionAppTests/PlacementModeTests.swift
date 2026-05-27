//
//  PlacementModeTests.swift
//  PlaneDetectionAppTests
//
//  Created by Claude on 5/20/26.
//

import Testing
@testable import PlaneDetectionApp

@Suite("PlacementMode Tests")
struct PlacementModeTests {
    
    @Test("PlacementMode enum values")
    func enumValues() {
        let imageMode = PlacementMode.image
        let modelMode = PlacementMode.model
        
        #expect(imageMode != modelMode)
    }
    
    @Test("PlacementMode can be compared")
    func comparison() {
        let mode1 = PlacementMode.image
        let mode2 = PlacementMode.image
        let mode3 = PlacementMode.model
        
        #expect(mode1 == mode2)
        #expect(mode1 != mode3)
    }
    
    @Test("PlacementMode can be switched")
    func switching() {
        var mode = PlacementMode.image
        #expect(mode == .image)
        
        mode = .model
        #expect(mode == .model)
        
        mode = .image
        #expect(mode == .image)
    }
}
