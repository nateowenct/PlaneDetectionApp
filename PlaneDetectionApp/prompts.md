# Prompt Templates

---

## Initial Project Setup

"Using the project specification and context file, generate the initial VisionOS app structure. Focus on:
- Correct RealityKit setup
- Plane detection
- Modular architecture
Do not implement advanced features yet."

---

## Implement Feature

"Implement [FEATURE NAME] according to the specification.

Follow all constraints:
- Do not introduce new frameworks
- Keep logic modular
- Follow anchoring and placement rules strictly
- Ensure gaze behavior is only visual feedback"

---

## Debug Issue

"The following issue is occurring:

[DESCRIBE ISSUE]

Analyze the root cause based on the spec and context.
Provide a targeted fix.
Do not rewrite unrelated code."

---

## Refactor Code

"Refactor this code to improve readability and modularity while:
- Preserving behavior
- Maintaining RealityKit best practices
- Avoiding unnecessary abstraction"

---

## Add Tests

"Generate unit tests for the following logic:
- Mode switching
- Placement decision logic

Do not attempt to test ARKit or RealityKit.
Keep tests simple and deterministic."
