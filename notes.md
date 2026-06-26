# Dev Notes

## Plane Overlay Rotation (~10° Y-axis skew)

ARKit aligns a `PlaneAnchor`'s transform to the detected plane's dominant edge direction, not world north. So `AnchorEntity(planeAnchor)` inherits an arbitrary Y rotation, and the overlay rectangle looks skewed relative to the table edge.

The overlay *is* correctly sitting on the surface — the rotation is cosmetic. Options:
1. **Counter-rotate the overlay** — apply an inverse Y rotation to cancel the anchor's yaw (visual fix only)
2. **Accept it** — overlay is on the surface, user has `RotateGesture3D` control over placements
3. **Snap to world Y** — manually construct anchor with no yaw (fights ARKit tracking)

**Decision pending** — may remove the transparent overlay entirely and replace with direct object selection (no overlay). Revisit when that change is scoped.

---

## Fragile Name-Based Dimension Encoding

`planeDimensions(for:)` and `planeAnchor(for:)` in `ARViewModel` parse dimensions and UUID out of the overlay entity's name string (e.g. `PlaneOverlay_<uuid>_<width>_<height>`). This is brittle.

**Proposed fix:** Add a custom `PlaneOverlayComponent: Component` that stores `uuid`, `width`, and `height` directly on the entity. Eliminates string parsing, is type-safe, and keeps dimensions in sync when planes update.

---

## Overlay Visibility Logic

`showPlaneOverlays()` / `hidePlaneOverlays()` are only triggered by `.onChange` on `selectedImage` / `selectedModelName`. But `addPlaneAnchor` always sets `overlay.isEnabled = true` unconditionally — so planes detected before content is selected still show their overlays.

**May be moot** if the overlay is removed in favor of direct placement selection.

---

## Path Data Coordinate Pipeline (Fan Movement → AR)

Data has `ENTRY_LATITUDE`, `ENTRY_LONGITUDE`, `EXIT_LATITUDE`, `EXIT_LONGITUDE` + timestamps. The full chain for placing path dots/lines in AR:

```
lat/lon → pixel (x,y) on image → normalized [0–1] → RealityKit local meters
```

**What you need:**
- 3 georeferenced reference points (already established: tennis house, big house pool, clubhouse pool) mapping pixel coords to lat/lon
- A simple affine transform derived from those points gives lat/lon → pixel
- Divide by image dimensions (1722×1374) to normalize, then multiply by the RealityKit plane's width/depth and center-offset (plane mesh is origin-centered)

**What you don't need from the notebook:**
- `deg_per_pixel` scale / `extent` / `extent_inverted` — those are matplotlib-specific
- `xy_to_latlon` conversion — no need to go back to lat/lon in AR
- Zone consolidation — optional, only needed if you want cleaned-up zone-to-zone movement vs raw GPS traces

**Accuracy:** 3 well-distributed reference points support a simple bilinear or affine transform, which is plenty accurate for venue-scale visualization.

**Data filtering:** Raw data has outlier x-meter range (-14,290 to +787,420m). Filter to points within the image's geographic bounding box before rendering.

**Y-axis note:** Pixel Y=0 is top of image = higher latitude. RealityKit's Z on a horizontal plane increases away from you. Flip the Y→Z mapping accordingly (same as `extent_inverted` in the notebook).

---

## 3D Topographic Model Path Overlay

If a topographic USDZ model of the venue is available:

**Georeferencing** — same pipeline as above. Identify real-world lat/lon of the model's bounding corners or known landmarks to establish the coordinate mapping. Path data drops onto it the same way.

**Scale** — need the real-world span of the model (e.g. "covers 500m × 300m of terrain") to derive the scale factor. `placeModel` already fits to plane dimensions — plane dimensions should match the venue's real-world aspect ratio.

**Y position via raycast** — for each path point at `(x, z)`, cast a ray straight down from above the model against its collision mesh. Use the hit Y + small offset (~0.01m) as the dot/line entity's Y position. RealityKit API: `scene.raycast(origin:direction:query:)`. The model needs a `CollisionComponent`, which `placeModel` already sets up.

Alternative (simpler, less accurate): fix all dots at a constant Y slightly above the model's bounding box top — ignores terrain contour, dots may float or clip on steep areas.

---

## USGS Lidar Data — Ballantyne / South Charlotte NC

Venue center: **35.1153° N, -80.8416° W** (Ballantyne Hotel & Golf Club area)

**Dataset found:** `NC_Phase4_Mecklenburg_2016`  
- Quality Level: QL1 (best tier, ~0.95m resolution)  
- Type: Geiger-mode LiDAR  
- Spec: USGS Lidar Base Specification 1.2  
- Collected: 2016/02/26 – 2017/02/20  

**S3 download path (public, no auth):**
```
https://prd-tnm.s3.amazonaws.com/index.html?prefix=StagedProducts/Elevation/OPR/Projects/NC_Phase_4_CentralWestNC_GEIGER_A16/NC_Phase4_Mecklenburg_2016
```

**Target bounding box for tile lookup:** ~35.110–35.120°N, -80.850–-80.835°W (likely 1-2 tiles)

**Python pipeline (to be scripted):**
1. Browse S3 index to find `.laz` tiles covering the bounding box
2. Download tiles via `requests` (no auth needed)
3. `laspy` — read, filter to bounding box, keep ground-classified points (class code 2)
4. `open3d` or `pyvista` — mesh via Poisson reconstruction
5. Export OBJ → `usdzconvert` (Reality Composer Pro CLI) → USDZ

Coordinate output should align with existing reference points (tennis house, big house pool, clubhouse pool) so georeferencing transfers directly to the model.
