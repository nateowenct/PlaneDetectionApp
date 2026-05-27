//
//  ImmersiveView.swift
//  PlaneDetectionApp
//
//  Created by Claude on 5/20/26.
//

import SwiftUI
import RealityKit
import ARKit

/// Immersive space for AR plane detection and placement
struct ImmersiveView: View {
    @Bindable var appState: AppState
    @State private var arViewModel = ARViewModel()
    @State private var rootEntity = Entity()
    @State private var gestureStartScale: Float = 0.75
    @State private var accumulatedYRotation: simd_quatf = .init(angle: 0, axis: [0, 1, 0])
    @State private var baseOrientation: simd_quatf = .init(angle: 0, axis: [0, 1, 0])
    
    var body: some View {
        ZStack {
            RealityView { content in
                content.add(rootEntity)
            } update: { content in
            }
            .task {
                await runPlaneDetection()
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        print("========== TAP DETECTED on entity: \(value.entity.name) ==========")
                        handleTap(on: value.entity)
                    }
            )
            .gesture(
                MagnifyGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        handleMagnifyChanged(value: value)
                    }
                    .onEnded { value in
                        handleMagnifyEnded(value: value)
                    }
                    .simultaneously(with:
                        RotateGesture3D(constrainedToAxis: .y)
                            .targetedToAnyEntity()
                            .onChanged { value in
                                handleRotateChanged(value: value)
                            }
                            .onEnded { value in
                                handleRotateEnded(value: value)
                            }
                    )
            )
            .onChange(of: appState.selectedImage) { oldValue, newValue in
                if newValue != nil {
                    arViewModel.showPlaneOverlays()
                } else if appState.selectedModelName == nil {
                    arViewModel.hidePlaneOverlays()
                }
            }
            .onChange(of: appState.selectedModelName) { oldValue, newValue in
                if newValue != nil {
                    arViewModel.showPlaneOverlays()
                } else if appState.selectedImage == nil {
                    arViewModel.hidePlaneOverlays()
                }
            }
        }
    }
    
    private func runPlaneDetection() async {
        let session = ARKitSession()
        let planeDetection = PlaneDetectionProvider(alignments: [.horizontal])
        
        do {
            print("Starting ARKit session...")
            try await session.run([planeDetection])
            print("ARKit session running, waiting for plane updates...")
            
            for await update in planeDetection.anchorUpdates {
                print("Plane update received: \(update.event)")
                handlePlaneUpdate(update)
            }
        } catch {
            print("Failed to start plane detection: \(error)")
        }
    }
    
    private func handlePlaneUpdate(_ update: AnchorUpdate<PlaneAnchor>) {
        let planeAnchor = update.anchor

        guard planeAnchor.alignment == .horizontal else {
            print("Skipping non-horizontal plane: \(planeAnchor.alignment)")
            return
        }

        let transform = planeAnchor.originFromAnchorTransform
        let planeY = transform.columns.3.y

        print("Plane Y position: \(planeY)m")

        if planeAnchor.surfaceClassification == .ceiling {
            print("Skipping plane classified as ceiling")
            return
        }

        guard planeY >= -2.0 && planeY <= 1.0 else {
            print("Skipping plane at Y=\(planeY)m (out of acceptable range)")
            return
        }
        
        switch update.event {
        case .added:
            print("Adding horizontal plane anchor: \(planeAnchor.id)")
            print("Plane Y position: \(planeY)m, classification: \(planeAnchor.surfaceClassification)")
            
            let anchorEntity = AnchorEntity(planeAnchor)
            rootEntity.addChild(anchorEntity)
            arViewModel.addPlaneAnchor(anchorEntity, id: planeAnchor.id, planeAnchor: planeAnchor)
            
            print("Plane added. Total anchors: \(rootEntity.children.count)")
            print("Image selected: \(appState.selectedImage != nil)")
            
        case .updated:
            print("Plane updated: \(planeAnchor.id)")
            arViewModel.updatePlaneAnchor(id: planeAnchor.id, planeAnchor: planeAnchor)
            
        case .removed:
            print("Plane removed: \(planeAnchor.id)")
            arViewModel.removePlaneAnchor(id: planeAnchor.id)
        }
    }
    
    private func handleTap(on entity: Entity) {
        print("========== TAP HANDLER ==========")
        print("Entity name: \(entity.name)")
        print("Entity type: \(type(of: entity))")
        print("Can place: \(appState.canPlace)")

        var currentEntity: Entity? = entity
        var depth = 0
        print("Checking entity hierarchy:")
        while currentEntity != nil {
            print("  Level \(depth): name=\(currentEntity?.name ?? "nil"), type=\(type(of: currentEntity!))")

            if currentEntity?.name == "PlacedImage" || currentEntity?.name == "PlacedModel" {
                print("✅ Found placed content at level \(depth) - removing it")
                appState.removeActivePlacement()
                arViewModel.showPlaneOverlays()
                return
            }
            currentEntity = currentEntity?.parent
            depth += 1

            if depth > 10 { break }
        }

        print("Not a placed entity, checking if can place...")

        guard appState.canPlace else {
            print("❌ Placement not allowed - existing placement must be removed first")
            return
        }

        guard let planeAnchor = arViewModel.planeAnchor(for: entity) else {
            print("❌ Tapped entity is not a plane overlay")
            return
        }

        guard let dimensions = arViewModel.planeDimensions(for: entity) else {
            print("❌ Failed to extract plane dimensions from overlay")
            return
        }

        print("✅ Placing content on tapped plane (dimensions: \(dimensions.width)m x \(dimensions.height)m)")

        appState.planeDimensions = dimensions
        appState.currentScale = 0.75
        gestureStartScale = 0.75
        appState.currentRotation = .zero
        accumulatedYRotation = .init(angle: 0, axis: [0, 1, 0])

        switch appState.placementMode {
        case .image:
            guard let image = appState.selectedImage else {
                print("❌ No image selected")
                return
            }
            print("Placing image, size: \(image.size)")
            if let imageEntity = arViewModel.placeImage(image, on: planeAnchor, planeWidth: dimensions.width, planeHeight: dimensions.height) {
                appState.activePlacement = imageEntity
                arViewModel.hidePlaneOverlays()
                print("✅ Image placed and tracked")
            } else {
                print("❌ Failed to place image")
            }

        case .model:
            guard let modelName = appState.selectedModelName else {
                print("❌ No model selected")
                return
            }
            print("Placing 3D model: \(modelName)")
            Task {
                if let modelEntity = await arViewModel.placeModel(modelName: modelName, on: planeAnchor, planeWidth: dimensions.width, planeHeight: dimensions.height) {
                    appState.activePlacement = modelEntity
                    appState.modelBaseScale = modelEntity.scale
                    baseOrientation = modelEntity.orientation
                    accumulatedYRotation = .init(angle: 0, axis: [0, 1, 0])
                    arViewModel.hidePlaneOverlays()
                    print("✅ Model placed and tracked, base scale: \(modelEntity.scale)")
                } else {
                    print("❌ Failed to place model")
                }
            }
        }
    }

    private func handleMagnifyChanged(value: EntityTargetValue<MagnifyGesture.Value>) {
        guard let entity = appState.activePlacement,
              let dimensions = appState.planeDimensions else {
            return
        }

        let magnification = Float(value.magnification)
        let newScale = gestureStartScale * magnification

        if let modelEntity = entity as? ModelEntity, modelEntity.name == "PlacedImage" {
            let clampedScale = max(0.25, min(1.0, newScale))
            guard let image = appState.selectedImage else { return }
            arViewModel.updateImageScale(modelEntity, image: image, scale: clampedScale, planeWidth: dimensions.width, planeHeight: dimensions.height)
        } else if entity.name == "PlacedModel", let baseScale = appState.modelBaseScale {
            let clampedScale = max(0.25, min(1.5, newScale))
            arViewModel.updateModelScale(entity, targetScale: clampedScale, baseScale: baseScale)
        }
    }

    private func handleMagnifyEnded(value: EntityTargetValue<MagnifyGesture.Value>) {
        guard let entity = appState.activePlacement,
              appState.planeDimensions != nil else {
            return
        }

        let magnification = Float(value.magnification)
        let newScale = gestureStartScale * magnification

        let maxScale: Float = entity.name == "PlacedModel" ? 1.5 : 1.0
        let clampedScale = max(0.25, min(maxScale, newScale))

        appState.currentScale = clampedScale
        gestureStartScale = clampedScale

        print("🔍 Magnify ended: final scale = \(clampedScale)")
    }

    private func handleRotateChanged(value: EntityTargetValue<RotateGesture3D.Value>) {
        guard let entity = appState.activePlacement,
              entity.name == "PlacedModel" else {
            return
        }

        let gestureQuat = simd_quatf(value.rotation)
        entity.orientation = gestureQuat * accumulatedYRotation * baseOrientation

        print("🔄 Rotating model")
    }

    private func handleRotateEnded(value: EntityTargetValue<RotateGesture3D.Value>) {
        guard appState.activePlacement?.name == "PlacedModel" else {
            return
        }

        let gestureQuat = simd_quatf(value.rotation)
        accumulatedYRotation = gestureQuat * accumulatedYRotation
        appState.currentRotation = Angle(radians: Double(gestureQuat.angle))

        print("🔄 Rotation ended and saved")
    }
}
