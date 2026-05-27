//
//  ARViewModel.swift
//  PlaneDetectionApp
//
//  Created by Claude on 5/20/26.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

/// Manages AR session, plane detection, and entity placement
@Observable
class ARViewModel {
    private var planeAnchors: [UUID: AnchorEntity] = [:]
    private var planeOverlays: [UUID: ModelEntity] = [:]
    private var currentlyGazedPlane: UUID?
    var currentlyGazedPlaneAnchor: AnchorEntity? {
        guard let planeId = currentlyGazedPlane else { return nil }
        return planeAnchors[planeId]
    }
    
    /// Place an image on the specified plane anchor, returns the image entity
    func placeImage(_ image: UIImage, on planeAnchor: AnchorEntity, planeWidth: Float, planeHeight: Float) -> ModelEntity? {
        print("🖼️ placeImage called")
        print("📐 Plane dimensions: \(planeWidth)m x \(planeHeight)m")
        
        // Create texture from image
        guard let cgImage = image.cgImage else {
            print("❌ Failed to get CGImage")
            return nil
        }
        print("✅ Got CGImage")
        
        guard let texture = try? TextureResource(image: cgImage, options: .init(semantic: .color)) else {
            print("❌ Failed to create texture")
            return nil
        }
        print("✅ Created texture")
        
        // Calculate size to be 75% of the plane, maintaining image aspect ratio
        let imageAspectRatio = Float(image.size.height / image.size.width)
        let planeAspectRatio = planeHeight / planeWidth
        
        let width: Float
        let height: Float
        
        // Scale to 75% of plane while maintaining image aspect ratio
        if imageAspectRatio > planeAspectRatio {
            // Image is taller relative to plane, constrain by height
            height = planeHeight * 0.75
            width = height / imageAspectRatio
        } else {
            // Image is wider relative to plane, constrain by width
            width = planeWidth * 0.75
            height = width * imageAspectRatio
        }
        
        print("📏 Image dimensions: \(width)m x \(height)m")
        
        // Create plane mesh and material
        let mesh = MeshResource.generatePlane(width: width, depth: height)
        var material = SimpleMaterial()
        material.color = .init(texture: .init(texture))
        
        let imageEntity = ModelEntity(mesh: mesh, materials: [material])
        imageEntity.name = "PlacedImage"

        // Enable input for tap gesture
        imageEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        imageEntity.components.set(CollisionComponent(shapes: [.generateBox(width: width, height: 0.01, depth: height)]))

        print("✅ Created image entity")

        // Position the image entity at the same position as the overlay (center of plane)
        imageEntity.position = [0, 0.002, 0]  // Just 2mm above plane surface, right where overlay is

        // Add the image directly to the plane anchor (where the overlay is)
        planeAnchor.addChild(imageEntity)
        
        print("✅ Image placed directly on plane anchor at position: \(imageEntity.position)")
        
        // Return the image entity so we can track it
        return imageEntity
    }
    
    /// Update the scale of a placed image entity
    func updateImageScale(_ entity: ModelEntity, image: UIImage, scale: Float, planeWidth: Float, planeHeight: Float) {
        print("🔄 Updating image scale to: \(scale)")

        // Calculate size maintaining image aspect ratio
        let imageAspectRatio = Float(image.size.height / image.size.width)
        let planeAspectRatio = planeHeight / planeWidth

        let width: Float
        let height: Float

        // Scale based on image aspect ratio
        if imageAspectRatio > planeAspectRatio {
            // Image is taller relative to plane, constrain by height
            height = planeHeight * scale
            width = height / imageAspectRatio
        } else {
            // Image is wider relative to plane, constrain by width
            width = planeWidth * scale
            height = width * imageAspectRatio
        }

        print("📏 New image dimensions: \(width)m x \(height)m")

        // Create new mesh with updated size
        let mesh = MeshResource.generatePlane(width: width, depth: height)
        entity.model?.mesh = mesh
    }

    /// Update the scale of a placed 3D model entity
    /// - Parameters:
    ///   - entity: The model entity to scale
    ///   - targetScale: Target scale as percentage of plane (0.25 to 1.5)
    ///   - baseScale: The entity's base scale vector (from initial 75% placement)
    func updateModelScale(_ entity: Entity, targetScale: Float, baseScale: SIMD3<Float>) {
        print("🔄 Updating model scale to \(targetScale * 100)% of plane")

        // Store original position
        let originalPosition = entity.position

        // Calculate new scale: baseScale represents 75% (0.75) of plane
        // We need to scale it proportionally to reach targetScale
        let scaleFactor = targetScale / 0.75
        let newScale = baseScale * scaleFactor

        entity.scale = newScale

        // Maintain the original position (keep it anchored to the plane)
        entity.position = originalPosition

        print("📏 Base scale: \(baseScale), Factor: \(scaleFactor), New scale: \(newScale), Position maintained at: \(originalPosition)")
    }

    /// Place a 3D model on the specified plane anchor
    func placeModel(modelName: String, on planeAnchor: AnchorEntity, planeWidth: Float, planeHeight: Float) async -> Entity? {
        print("📐 Plane dimensions for model: \(planeWidth)m x \(planeHeight)m")

        do {
            // Load the model from RealityKitContent bundle
            let entity = try await Entity(named: modelName, in: realityKitContentBundle)

            print("✅ Loaded \(modelName) model")
            print("📐 Original entity orientation: \(entity.orientation)")

            // Create a wrapper entity to ensure clean rotation without fighting model's internal orientation
            let wrapper = Entity()

            // Apply rotation to wrapper to lay flat on the plane
            wrapper.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])

            // Keep entity at origin within wrapper
            entity.position = [0, 0, 0]
            entity.orientation = .init(angle: 0, axis: [0, 1, 0])  // Identity rotation

            // Add input/collision to the actual model entity (before adding to wrapper)
            // This ensures the collision box is oriented with the model's geometry
            let modelBounds = entity.visualBounds(relativeTo: entity)
            let modelCollisionWidth = max(modelBounds.extents.x * 2.0, 0.3)
            let modelCollisionHeight = max(modelBounds.extents.y * 2.0, 0.3)
            let modelCollisionDepth = max(modelBounds.extents.z * 2.0, 0.3)

            print("📦 Model collision box: \(modelCollisionWidth)m x \(modelCollisionHeight)m x \(modelCollisionDepth)m")

            entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
            entity.components.set(CollisionComponent(shapes: [.generateBox(
                width: modelCollisionWidth,
                height: modelCollisionHeight,
                depth: modelCollisionDepth
            )]))
            entity.components.set(HoverEffectComponent())

            // Now add to wrapper
            wrapper.addChild(entity)

            print("📐 Wrapper orientation set to lay flat on plane")

            // Use wrapper as the entity to work with
            let modelEntity = wrapper

            // Get initial bounds to calculate dimensions
            let initialBounds = modelEntity.visualBounds(relativeTo: modelEntity)
            let modelWidth = initialBounds.extents.x
            let modelDepth = initialBounds.extents.z
            let modelHeight = initialBounds.extents.y

            print("📏 Original model size: \(modelWidth)m x \(modelDepth)m x \(modelHeight)m")

            // Calculate scale to fit 75% of the plane
            let targetWidth = planeWidth * 0.75
            let targetDepth = planeHeight * 0.75

            let scaleX = targetWidth / modelWidth
            let scaleZ = targetDepth / modelDepth
            let scale = min(scaleX, scaleZ)

            modelEntity.scale = [scale, scale, scale]

            print("📏 Applied scale: \(scale)")

            // Position at center of plane, slightly above surface (2mm)
            // In the plane anchor's coordinate system, [0,0,0] is the center of the plane
            modelEntity.position = [0, 0.002, 0]
            modelEntity.name = "PlacedModel"

            print("📍 Model positioned at: \(modelEntity.position) relative to plane anchor")

            // Add to plane anchor LAST after all transforms are set
            planeAnchor.addChild(modelEntity)

            print("✅ Model placed and scaled")
            return modelEntity

        } catch {
            print("❌ Error loading model: \(error)")
            return nil
        }
    }
    
    /// Register a detected plane anchor
    func addPlaneAnchor(_ anchor: AnchorEntity, id: UUID, planeAnchor: PlaneAnchor) {
        planeAnchors[id] = anchor

        // Get plane dimensions from geometry
        let geometry = planeAnchor.geometry
        let width = geometry.extent.width
        let height = geometry.extent.height

        print("Plane dimensions: \(width)m x \(height)m")

        // Create plane overlay sized to match the plane (always visible for now)
        let overlay = createPlaneOverlay(width: width, height: height)
        overlay.isEnabled = true  // Always visible
        anchor.addChild(overlay)
        planeOverlays[id] = overlay

        // Store the plane ID and dimensions in the overlay's name for lookup
        overlay.name = "PlaneOverlay_\(id.uuidString)_\(width)_\(height)"

        print("Created overlay for plane \(id)")
    }
    
    /// Update a plane anchor's overlay when the plane geometry changes
    func updatePlaneAnchor(id: UUID, planeAnchor: PlaneAnchor) {
        guard let overlay = planeOverlays[id] else { return }
        
        let geometry = planeAnchor.geometry
        let width = geometry.extent.width
        let height = geometry.extent.height
        
        // Update the overlay mesh to match new dimensions
        let newMesh = MeshResource.generatePlane(width: width, depth: height)
        overlay.model?.mesh = newMesh
        
        print("Updated plane \(id) dimensions: \(width)m x \(height)m")
    }
    
    /// Show all plane overlays
    func showPlaneOverlays() {
        for overlay in planeOverlays.values {
            overlay.isEnabled = true
        }
    }
    
    /// Hide all plane overlays
    func hidePlaneOverlays() {
        for overlay in planeOverlays.values {
            overlay.isEnabled = false
        }
    }
    
    /// Remove a plane anchor that is no longer detected
    func removePlaneAnchor(id: UUID) {
        planeAnchors[id]?.removeFromParent()
        planeAnchors.removeValue(forKey: id)
        planeOverlays.removeValue(forKey: id)
    }
    
    /// Update plane overlay based on gaze
    func updateGaze(planeId: UUID?) {
        // Reset previous gaze state
        if let previousId = currentlyGazedPlane,
           let overlay = planeOverlays[previousId] {
            updateOverlayAppearance(overlay, gazed: false)
        }
        
        // Set new gaze state
        currentlyGazedPlane = planeId
        if let newId = planeId,
           let overlay = planeOverlays[newId] {
            updateOverlayAppearance(overlay, gazed: true)
        }
    }
    
    /// Get plane anchor by ID
    func planeAnchor(for id: UUID) -> AnchorEntity? {
        planeAnchors[id]
    }
    
    /// Get the first available plane anchor for placement
    func getFirstPlaneAnchor() -> AnchorEntity? {
        planeAnchors.values.first
    }
    
    /// Find the plane anchor and dimensions for a given overlay entity
    func planeAnchor(for overlay: Entity) -> AnchorEntity? {
        // Extract UUID from overlay name (format: "PlaneOverlay_<UUID>_<width>_<height>")
        let name = overlay.name
        guard name.hasPrefix("PlaneOverlay_") else {
            return nil
        }

        let parts = name.split(separator: "_")
        guard parts.count >= 2 else { return nil }

        let uuidString = String(parts[1])
        guard let uuid = UUID(uuidString: uuidString) else {
            return nil
        }

        return planeAnchors[uuid]
    }

    /// Extract plane dimensions from overlay entity name
    func planeDimensions(for overlay: Entity) -> (width: Float, height: Float)? {
        // Extract dimensions from overlay name (format: "PlaneOverlay_<UUID>_<width>_<height>")
        let name = overlay.name
        guard name.hasPrefix("PlaneOverlay_") else {
            return nil
        }

        let parts = name.split(separator: "_")
        guard parts.count >= 4 else { return nil }

        guard let width = Float(String(parts[2])),
              let height = Float(String(parts[3])) else {
            return nil
        }

        return (width, height)
    }
    
    // MARK: - Private Methods

    private func createPlaneOverlay(width: Float, height: Float) -> ModelEntity {
        // Create overlay sized to match the detected plane
        let mesh = MeshResource.generatePlane(width: width, depth: height)
        var material = SimpleMaterial()
        // Transparent overlay - subtle and non-intrusive
        material.color = .init(tint: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.15))

        let overlay = ModelEntity(mesh: mesh, materials: [material])
        overlay.name = "PlaneOverlay"

        // Lift slightly above the plane surface to avoid z-fighting
        overlay.position = [0, 0.001, 0]  // 1mm above the plane

        // Don't set orientation - let it inherit from the plane anchor
        // The plane anchor already has the correct orientation from ARKit

        // Enable input and hover for gaze detection
        overlay.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        overlay.components.set(CollisionComponent(shapes: [.generateBox(width: width, height: 0.01, depth: height)]))
        overlay.components.set(HoverEffectComponent())

        return overlay
    }

    private func updateOverlayAppearance(_ overlay: ModelEntity, gazed: Bool) {
        var material = SimpleMaterial()

        if gazed {
            // Subtle light blue when gazed
            material.color = .init(tint: UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.3))
        } else {
            // Transparent when not gazed
            material.color = .init(tint: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.15))
        }

        overlay.model?.materials = [material]
    }
}
