# VisionOS Plane Placement App

---

## Overview

This app allows users to detect horizontal surfaces in their environment and place either a 2D image (from their photo library) or a 3D model onto those surfaces.

---

## Key Features

- Horizontal plane detection
- Transparent visual overlays for detected planes
- Gaze-based visual feedback:
  - Light blue highlight when gazed
  - Dark blue border on active plane
- Tap to place content
- Image selection from photo library
- Toggle between image and 3D model placement
- Single placement at a time
- Ability to remove placed content

---

## Interaction Model

- Gaze: Provides visual feedback only (no interaction)
- Tap:
  - On plane → places content
  - Off plane → no action

---

## Image Placement Behavior

- Images are selected from the user's photo library
- Images are applied to a flat plane entity
- Image scales to fit:
  - Width OR height depending on aspect ratio
- No distortion of image

---

## Model Placement Behavior

- Models are loaded from local app bundle (USDZ)
- Correctly positioned and anchored to plane
- Properly scaled and aligned

---

## Constraints

- Only one content placement allowed at a time
- Existing content must be removed before placing new content
- No gesture interactions (no scaling, rotation, drag)
- No persistence (no saving state)
- No networking
- No physics simulation

---

## Tech Stack

- Swift
- SwiftUI
- RealityKit
- ARKit
- Photos Framework

---

## Testing

- Unit tests cover core application logic:
  - Mode switching
  - Placement enforcement
  - Removal logic
- Rendering and ARKit behavior are NOT tested

---

## Notes

This project focuses on:
- Correct spatial anchoring
- Predictable interaction behavior
- Clean and maintainable code
- Exploring AI-assisted development workflows

---

## Minimum VisionOS Version

This project targets a minimum supported VisionOS version (to be defined in project settings).
