//
//  DSSheet.swift
//  mobileIOS
//
//  Base sheet component with consistent form layout (Cancel/Save in nav bar)
//

import SwiftUI

struct DSSheet<Content: View>: View {
    let title: String
    let onCancel: () -> Void
    let onSave: () async -> Void
    let canSave: Bool
    @ViewBuilder let content: () -> Content
    
    @State private var isSaving = false
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    content()
                }
                .padding()
            }
            .background(DSTheme.colors(for: scheme).backgroundPrimary)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            await onSave()
                            isSaving = false
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("Saving...")
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial))
                        }
                }
            }
        }
    }
}

// MARK: - Form Validation Helper

protocol FormValidatable {
    var isValid: Bool { get }
    var validationErrors: [String] { get }
}

struct FormValidationView: View {
    let errors: [String]
    
    var body: some View {
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(errors, id: \.self) { error in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text(error)
                            .dsFont(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.1))
            )
        }
    }
}

// MARK: - Common Sheet View Models

@MainActor
class SheetViewModel: ObservableObject {
    @Published var isPresented = false
    @Published var isLoading = false
    @Published var error: String?
    
    func dismiss() {
        isPresented = false
        error = nil
    }
    
    func showError(_ message: String) {
        error = message
    }
}
