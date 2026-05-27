//
//  ModelPickerView.swift
//  PlaneDetectionApp
//
//  Created by Claude on 5/27/26.
//

import SwiftUI

/// View for selecting a 3D model from available models
struct ModelPickerView: View {
    @Binding var selectedModelName: String?
    @Environment(\.dismiss) private var dismiss
    let availableModels: [String]

    var body: some View {
        NavigationStack {
            List(availableModels, id: \.self) { modelName in
                Button(action: {
                    selectedModelName = modelName
                    dismiss()
                }) {
                    HStack {
                        Text(formatModelName(modelName))
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedModelName == modelName {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Model")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    /// Format model name for display (convert underscores to spaces, capitalize)
    private func formatModelName(_ name: String) -> String {
        name.replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

#Preview {
    ModelPickerView(
        selectedModelName: .constant(nil),
        availableModels: ["tennis_court_with_mini_golf"]
    )
}
