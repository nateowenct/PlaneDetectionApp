//
//  TerrainPathOverlay.swift
//  PlaneDetectionApp
//

import Foundation
import RealityKit
import simd
internal import UIKit

// MARK: - Path data model

struct PathPoint: Decodable {
    let x: Float
    let y: Float
    let timestamp: String
}

// MARK: - Terrain coordinate constants

/// Matches the Python mesh generation exactly:
///   DOWNSAMPLE = 4, pixel_size = 3.125m → xy_scale = 12.5m/vertex
///   Grid: 365 cols × 298 rows → 4562.5m wide × 3725.0m tall
///   Origin (0,0,0) = NW corner (min_lon, max_lat)
///   X increases eastward, Z increases southward
enum TerrainConstants {
    static let venueBounds = (
        minLat: Float(35.110), maxLat: Float(35.120),
        minLon: Float(-80.850), maxLon: Float(-80.835)
    )
    static let meshWidthMeters: Float  = 4562.5
    static let meshHeightMeters: Float = 3725.0
    static let centerLat: Float = 35.115339
    static let centerLon: Float = -80.841604
    static let metersPerDegree: Float = 111_000.0
}

// MARK: - Coordinate mapping

/// Converts a path point's (x, y) offset in meters from venue center → terrain local (x, z).
/// Returns nil if the point falls outside the mesh footprint.
func terrainLocalXZ(pathX: Float, pathY: Float) -> SIMD2<Float>? {
    let b = TerrainConstants.venueBounds

    let lat = TerrainConstants.centerLat + pathY / TerrainConstants.metersPerDegree
    let lon = TerrainConstants.centerLon + pathX / TerrainConstants.metersPerDegree

    guard lat >= b.minLat, lat <= b.maxLat,
          lon >= b.minLon, lon <= b.maxLon else {
        return nil
    }

    let localX = (lon - b.minLon) / (b.maxLon - b.minLon) * TerrainConstants.meshWidthMeters
    let localZ = (b.maxLat - lat) / (b.maxLat - b.minLat) * TerrainConstants.meshHeightMeters

    return SIMD2<Float>(localX, localZ)
}

// MARK: - Dot placement with raycasting

/// Loads path JSON from the app bundle, maps each point onto the terrain entity,
/// raycasts to find the surface Y, and attaches sphere children to the terrain entity.
func attachPathDots(to terrainEntity: Entity, scene: RealityKit.Scene?) async {
    guard let url = Bundle.main.url(forResource: "ar_path", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let points = try? JSONDecoder().decode([PathPoint].self, from: data) else {
        print("⚠️ TerrainPathOverlay: could not load ar_path.json from bundle")
        return
    }

    // Subsample to avoid memory pressure — every 20th point ~400 dots from 8000+
    let stride = 20
    let sampled = stride > 1 ? points.enumerated().compactMap { $0.offset % stride == 0 ? $0.element : nil } : points

    print("📍 Attaching \(sampled.count) path dots to terrain (sampled from \(points.count))")

    // Shared meshes and materials
    let dotMesh = MeshResource.generateSphere(radius: 12.0)
    let dotMaterial = UnlitMaterial(color: .cyan)
    let segMaterial = UnlitMaterial(color: UIColor(red: 0, green: 1, blue: 1, alpha: 0.85))

    var placed = 0
    var skipped = 0
    var resolvedPositions: [SIMD3<Float>] = []

    // First pass: resolve all 3D positions via raycast
    for point in sampled {
        guard let xz = terrainLocalXZ(pathX: point.x, pathY: point.y) else {
            skipped += 1
            continue
        }

        let rayOrigin = SIMD3<Float>(xz.x, 2000.0, xz.y)
        let rayDirection = SIMD3<Float>(0, -1, 0)
        var dotY: Float = 50.0

        if let scene = scene {
            let hits = scene.raycast(
                origin: rayOrigin,
                direction: rayDirection,
                length: 4000.0,
                query: .nearest,
                mask: .all,
                relativeTo: terrainEntity
            )
            if let hit = hits.first {
                dotY = hit.position.y + 8.0
            }
        }

        resolvedPositions.append(SIMD3<Float>(xz.x, dotY, xz.y))
        placed += 1
    }

    // Second pass: place dots
    for pos in resolvedPositions {
        let dot = ModelEntity(mesh: dotMesh, materials: [dotMaterial])
        dot.name = "PathDot"
        dot.position = pos
        terrainEntity.addChild(dot)
    }

    // Third pass: place line segments between consecutive dots
    for i in 0..<(resolvedPositions.count - 1) {
        let a = resolvedPositions[i]
        let b = resolvedPositions[i + 1]

        let diff = b - a
        let length = simd_length(diff)
        guard length > 0.1 else { continue }

        let midpoint = (a + b) * 0.5
        let direction = simd_normalize(diff)

        // Rotate the Z-axis aligned box to point from a to b
        let zAxis = SIMD3<Float>(0, 0, 1)
        let rotation = simd_quatf(from: zAxis, to: direction)

        let seg = ModelEntity(mesh: MeshResource.generateBox(size: SIMD3<Float>(6.0, 6.0, length)), materials: [segMaterial])
        seg.name = "PathSegment"
        seg.position = midpoint
        seg.orientation = rotation
        terrainEntity.addChild(seg)
    }

    print("✅ Path dots: \(placed) placed, \(skipped) outside venue bounds, \(resolvedPositions.count - 1) segments")
}
