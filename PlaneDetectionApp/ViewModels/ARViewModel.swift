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

    func placeImage(_ image: UIImage, on planeAnchor: AnchorEntity, planeWidth: Float, planeHeight: Float) -> ModelEntity? {
        print("🖼️ placeImage called")
        print("📐 Plane dimensions: \(planeWidth)m x \(planeHeight)m")

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
        let imageAspectRatio = Float(image.size.height / image.size.width)
        let planeAspectRatio = planeHeight / planeWidth
        
        let width: Float
        let height: Float

        if imageAspectRatio > planeAspectRatio {
            height = planeHeight * 0.75
            width = height / imageAspectRatio
        } else {
            width = planeWidth * 0.75
            height = width * imageAspectRatio
        }

        print("📏 Image dimensions: \(width)m x \(height)m")

        let mesh = MeshResource.generatePlane(width: width, depth: height)
        var material = SimpleMaterial()
        material.color = .init(texture: .init(texture))

        let imageEntity = ModelEntity(mesh: mesh, materials: [material])
        imageEntity.name = "PlacedImage"

        imageEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        imageEntity.components.set(CollisionComponent(shapes: [.generateBox(width: width, height: 0.01, depth: height)]))

        print("✅ Created image entity")

        imageEntity.position = [0, 0.002, 0]

        planeAnchor.addChild(imageEntity)

        print("✅ Image placed directly on plane anchor at position: \(imageEntity.position)")

        return imageEntity
    }
    
    func updateImageScale(_ entity: ModelEntity, image: UIImage, scale: Float, planeWidth: Float, planeHeight: Float) {
        print("🔄 Updating image scale to: \(scale)")

        let imageAspectRatio = Float(image.size.height / image.size.width)
        let planeAspectRatio = planeHeight / planeWidth

        let width: Float
        let height: Float

        if imageAspectRatio > planeAspectRatio {
            height = planeHeight * scale
            width = height / imageAspectRatio
        } else {
            width = planeWidth * scale
            height = width * imageAspectRatio
        }

        print("📏 New image dimensions: \(width)m x \(height)m")

        let mesh = MeshResource.generatePlane(width: width, depth: height)
        entity.model?.mesh = mesh
    }

    func updateModelScale(_ entity: Entity, targetScale: Float, baseScale: SIMD3<Float>) {
        print("🔄 Updating model scale to \(targetScale * 100)% of plane")

        let originalPosition = entity.position

        let scaleFactor = targetScale / 0.75
        let newScale = baseScale * scaleFactor

        entity.scale = newScale
        entity.position = originalPosition

        print("📏 Base scale: \(baseScale), Factor: \(scaleFactor), New scale: \(newScale), Position maintained at: \(originalPosition)")
    }

    func placeModel(modelName: String, on planeAnchor: AnchorEntity, planeWidth: Float, planeHeight: Float) async -> Entity? {
        print("📐 Plane dimensions for model: \(planeWidth)m x \(planeHeight)m")

        do {
            let entity = try await Entity(named: modelName, in: realityKitContentBundle)

            print("✅ Loaded \(modelName) model")
            print("📐 Original entity orientation: \(entity.orientation)")

            let wrapper = Entity()
            wrapper.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])

            entity.position = [0, 0, 0]
            entity.orientation = .init(angle: 0, axis: [0, 1, 0])

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

            wrapper.addChild(entity)

            print("📐 Wrapper orientation set to lay flat on plane")

            let modelEntity = wrapper

            let initialBounds = modelEntity.visualBounds(relativeTo: modelEntity)
            let modelWidth = initialBounds.extents.x
            let modelDepth = initialBounds.extents.z

            print("📏 Original model size: \(modelWidth)m x \(modelDepth)m")

            let targetWidth = planeWidth * 0.75
            let targetDepth = planeHeight * 0.75

            let scaleX = targetWidth / modelWidth
            let scaleZ = targetDepth / modelDepth
            let scale = min(scaleX, scaleZ)

            modelEntity.scale = [scale, scale, scale]

            print("📏 Applied scale: \(scale)")

            modelEntity.position = [0, 0.002, 0]
            modelEntity.name = "PlacedModel"

            print("📍 Model positioned at: \(modelEntity.position) relative to plane anchor")

            planeAnchor.addChild(modelEntity)

            print("✅ Model placed and scaled")
            return modelEntity

        } catch {
            print("❌ Error loading model: \(error)")
            return nil
        }
    }
    
    func addPlaneAnchor(_ anchor: AnchorEntity, id: UUID, planeAnchor: PlaneAnchor) {
        planeAnchors[id] = anchor

        let geometry = planeAnchor.geometry
        let width = geometry.extent.width
        let height = geometry.extent.height

        print("Plane dimensions: \(width)m x \(height)m")

        let overlay = createPlaneOverlay(width: width, height: height)
        overlay.isEnabled = true
        anchor.addChild(overlay)
        planeOverlays[id] = overlay

        overlay.name = "PlaneOverlay_\(id.uuidString)_\(width)_\(height)"

        print("Created overlay for plane \(id)")
    }

    func updatePlaneAnchor(id: UUID, planeAnchor: PlaneAnchor) {
        guard let overlay = planeOverlays[id] else { return }

        let geometry = planeAnchor.geometry
        let width = geometry.extent.width
        let height = geometry.extent.height

        let newMesh = MeshResource.generatePlane(width: width, depth: height)
        overlay.model?.mesh = newMesh

        print("Updated plane \(id) dimensions: \(width)m x \(height)m")
    }
    
    func showPlaneOverlays() {
        for overlay in planeOverlays.values {
            overlay.isEnabled = true
        }
    }

    func hidePlaneOverlays() {
        for overlay in planeOverlays.values {
            overlay.isEnabled = false
        }
    }

    func removePlaneAnchor(id: UUID) {
        planeAnchors[id]?.removeFromParent()
        planeAnchors.removeValue(forKey: id)
        planeOverlays.removeValue(forKey: id)
    }

    func planeAnchor(for overlay: Entity) -> AnchorEntity? {
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

    func planeDimensions(for overlay: Entity) -> (width: Float, height: Float)? {
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

    private func createPlaneOverlay(width: Float, height: Float) -> ModelEntity {
        let mesh = MeshResource.generatePlane(width: width, depth: height)
        var material = SimpleMaterial()
        material.color = .init(tint: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.15))

        let overlay = ModelEntity(mesh: mesh, materials: [material])
        overlay.name = "PlaneOverlay"

        overlay.position = [0, 0.001, 0]

        overlay.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        overlay.components.set(CollisionComponent(shapes: [.generateBox(width: width, height: 0.01, depth: height)]))
        overlay.components.set(HoverEffectComponent())

        return overlay
    }
}
