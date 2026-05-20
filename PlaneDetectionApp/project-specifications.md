# VisionOS Plane Placement App — Project Specification

---

## 1. Purpose

Build a VisionOS application that allows users to detect real-world horizontal surfaces and place either a 2D image (from the user’s photo library) or a 3D model onto those surfaces using simple tap interaction.

The goal of this project is to explore AI-assisted rapid development in a spatial computing context while maintaining a clear, minimal, and well-structured architecture.

---

## 2. Definition of Done

The project is considered complete when:

- The app successfully detects horizontal planes in the environment
- All detected planes display a subtle transparent visual indicator
- The visual indicator responds to user gaze with a highlighted state
- The user can tap on a detected plane to place content
- The user can toggle between:
  - 2D image placement (photo library)
  - 3D model placement
- Only one piece of content (image OR model) can exist at a time
- Users can remove existing content before placing a new one
- Content is correctly anchored to the detected plane and remains stable
- Unit tests are implemented for core application logic
- The app runs successfully in the VisionOS simulator or on device without crashes
- App targets a defined minimum VisionOS version
- Code structure is modular and aligns with defined constraints

---

## 3. Scope & Constraints

### In Scope
- Horizontal plane detection
- Visual plane indicators (transparent overlays)
- Gaze-based visual feedback for planes
- Tap-based placement interaction
- Image selection via photo library
- Toggle between content types (image vs. model)
- Single active placement at a time
- Removal of placed content
- Unit testing for core logic

### Out of Scope
- Persistence (no saving/loading placed items)
- Gesture interactions (no scaling, rotation, drag)
- Physics simulation
- Multi-user or shared experiences
- Advanced UI systems
- UI automation or integration testing

### Constraints
- Use only native VisionOS tools (SwiftUI + RealityKit + ARKit)
- Target a specified minimum VisionOS version
- Keep architecture simple and readable
- Avoid unnecessary abstractions or additional frameworks
- Focus on correctness and clarity over optimization
- Do not test ARKit or RealityKit internals directly

---

## 4. Assumptions

- Only horizontal planes will be supported
- User interaction is limited to:
  - Gaze (visual feedback only)
  - Tap (placement)
- Only one active placed entity is allowed at a time
- All 3D models are stored locally in the app bundle
- Images are selected from the user’s photo library
- No advanced error recovery for extreme edge cases

---

## 5. Features & Acceptance Criteria

---

### 5.1 Plane Detection

Detect horizontal surfaces in the user's environment.

**Acceptance Criteria:**
- The app identifies horizontal planes
- Plane detection updates dynamically as the environment changes
- The system remains stable if no planes are detected

---

### 5.2 Plane Visualization

Render visual indicators for all detected planes.

**Acceptance Criteria:**
- Each detected horizontal plane displays a transparent rectangular overlay
- The overlay aligns correctly with the plane surface
- The overlay remains lightweight and does not clutter the scene
- Overlays update or disappear as plane detection changes

---

### 5.3 Gaze-Based Visual Feedback

Provide visual feedback when the user gazes at a detected plane.

**Acceptance Criteria:**
- When gazing at a plane, the overlay:
  - Changes to a subtle light blue shade
  - Displays a dark blue border
- When gaze leaves the plane, the overlay returns to transparent state
- Feedback is smooth and does not flicker excessively
- Gaze does NOT trigger placement or interaction

---

### 5.4 Tap to Place Content

Enable users to place content on detected surfaces.

**Acceptance Criteria:**
- User can tap on a detected plane to place content
- Taps on non-plane areas result in no action
- Placement is ignored if no valid plane is selected
- Existing content must be removed before placing new content

---

### 5.5 Content Mode Toggle

Allow switching between image and 3D model placement.

**Acceptance Criteria:**
- User can toggle between:
  - “Image Mode”
  - “3D Model Mode”
- Default mode is Image Mode
- Selected mode determines placement behavior
- Mode switches immediately without restart

---

### 5.6 2D Image Placement (Photo Library)

Place an image selected from the user’s photo library.

**Acceptance Criteria:**
- User is prompted to select an image from the photo library
- Selected image is applied to a flat plane entity
- Image scales to fill the surface:
  - Fits to width or height based on aspect ratio
- Image is aligned with the horizontal plane
- Image appears correctly oriented and not distorted

---

### 5.7 3D Model Placement

Place a 3D model onto a detected surface.

**Acceptance Criteria:**
- Model loads from local app bundle
- Model appears at tap location
- Model is correctly scaled and oriented
- Model sits properly on the surface (not floating or clipping)

---

### 5.8 Content Management (Single Placement)

Ensure only one object is placed at a time.

**Acceptance Criteria:**
- Only one active entity (image or model) exists at a time
- Attempting to place a new entity without removing existing one is prevented
- User can remove existing content through defined interaction (e.g., UI button)
- Removal clears the current anchor and entity cleanly

---

## 6. Data Model & Scene Model

### Entity Structure

- Plane Anchors:
  - AnchorEntity (for each detected plane)

- Plane Visual Overlay:
  - ModelEntity (transparent plane with shading/border states)

- Placement Anchor:
  - AnchorEntity (single active placement)

- Content Entities:
  - ImageEntity (plane mesh with image texture)
  - ModelEntity (USDZ asset)
