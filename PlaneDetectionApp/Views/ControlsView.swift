//
//  ControlsView.swift
//  PlaneDetectionApp
//
//  Created by Claude on 5/20/26.
//

import SwiftUI

/// UI controls for mode selection and placement management
struct ControlsView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("Placement Mode", selection: $appState.placementMode) {
                Text("Image").tag(PlacementMode.image)
                Text("Model").tag(PlacementMode.model)
            }
            .pickerStyle(.segmented)

            if appState.placementMode == .image {
                Button(action: {
                    appState.showPhotoPicker = true
                }) {
                    Label("Select Photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if appState.placementMode == .model {
                Button(action: {
                    appState.showModelPicker = true
                }) {
                    Label("Select Model", systemImage: "cube.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if appState.activePlacement != nil {
                Button(action: {
                    appState.removeActivePlacement()
                }) {
                    Label("Remove Placement", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }

            if !appState.canPlace {
                Text("Remove current placement to add new content")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if appState.placementMode == .image {
                if let selectedImage = appState.selectedImage {
                    VStack(spacing: 8) {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .cornerRadius(8)

                        Text("Photo selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Select a photo to place")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if appState.placementMode == .model {
                if let modelName = appState.selectedModelName {
                    VStack(spacing: 8) {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text(formatModelName(modelName))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Select a model to place")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .sheet(isPresented: $appState.showPhotoPicker) {
            PhotoPickerView(selectedImage: $appState.selectedImage)
        }
        .sheet(isPresented: $appState.showModelPicker) {
            ModelPickerView(selectedModelName: $appState.selectedModelName, availableModels: appState.availableModels)
        }
    }

    private func formatModelName(_ name: String) -> String {
        name.replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

#Preview {
    ControlsView(appState: AppState())
}
