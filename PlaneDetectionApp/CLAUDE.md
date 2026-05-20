# VisionOS Plane Placement App - AI Development Context

---

## Project Overview

This is a VisionOS application built using Swift, SwiftUI, RealityKit, and ARKit.

The app detects horizontal planes and allows users to place either:
- A 2D image (selected from the user's photo library)
- A 3D model (USDZ asset)

Users interact using:
- Gaze (visual feedback only)
- Tap (for placement)

---

## Core Behavior

- Detect horizontal planes using ARKit
- Render a visual overlay on all detected planes
- Allow user to tap planes to place content
- Allow only ONE active placement at a time
- Provide mechanism to remove existing placement before adding a new one

---

## Plane Visualization

- Each detected plane must display a transparent rectangular overlay
- Overlay must align with the horizontal plane surface
- Overlay should be subtle and non-intrusive

### Gaze Behavior

- When user gazes at a plane:
  - Overlay background changes to a subtle light blue
  - Overlay shows a dark blue border
- When gaze leaves the plane:
  - Overlay returns to transparent state

### Critical Constraints

- Gaze is ONLY used for visual feedback
- Gaze must NOT trigger placement
- Avoid flickering or rapid state switching

---

## Placement Rules

- Placement can only occur on detected planes
- Tapping outside a plane must do NOTHING
- Only ONE placement (image or model) exists at a time
- New placement is blocked until current content is removed
- Provide clear mechanism to remove existing placement

---

## Image Placement (Photo Library)

- Images must be selected from the user's photo library using native APIs
- Selected image is mapped onto a flat plane (ModelEntity)

### Scaling Rules

- Image must scale to fit:
  - Entire width OR
  - Entire height
- Scaling should respect aspect ratio
- Image should not distort or stretch incorrectly

---

## 3D Model Placement

- Models are loaded from local app bundle (USDZ)
- Models must:
  - Appear at tap position
  - Sit correctly on plane
  - Not float or clip into surface

---

## Scene & Entity Management

- Each detected plane has its own AnchorEntity
- Overlays are attached to plane anchors
- Placement uses a single dedicated AnchorEntity

### Critical Rules

- All entities must be anchored
- Never leave entities in world space without anchor
- Do not reuse entities across placements

---

## UI Guidelines

- Use SwiftUI for:
  - Mode toggle (Image vs Model)
  - Remove placement control
- Keep UI minimal and functional
- Avoid complex layouts or navigation

---

## Tech Constraints

- Swift + SwiftUI + RealityKit + ARKit
- Use Photos framework for image selection
- Target a minimum supported VisionOS version (explicitly defined in project)

---

## Testing Requirements

### Required

- Unit tests for:
  - Placement mode logic
  - Single-placement enforcement
  - Removal logic

### Forbidden

- Do NOT test:
  - ARKit plane detection
  - RealityKit rendering

### Rules

- Tests must run independently of VisionOS runtime
- Tests must be deterministic and isolated

---

## Command Execution Constraints

- Do not run or suggest git commands (init, commit, push, checkout)
- Do not execute shell commands unless explicitly requested
- Only generate code and explanations

---

## Common Pitfalls to Avoid

- Placing entities without anchors (causes floating/drift)
- Treating gaze as a tap or hover trigger
- Adding gesture interactions (scaling, rotation)
- Attempting to test ARKit or RealityKit internals
- Overcomplicating architecture
- Mis-scaling image assets (breaking aspect ratio)
- Allowing multiple placements simultaneously

---

## Development Priorities

1. Correct plane detection + overlay rendering
2. Accurate gaze-based visual feedback
3. Proper anchoring behavior
4. Single-placement logic with removal flow
5. Clean and maintainable code
