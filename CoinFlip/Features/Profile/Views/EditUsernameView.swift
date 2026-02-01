import SwiftUI

struct EditUsernameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    @State private var newUsername: String
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _newUsername = State(initialValue: viewModel.username)
    }

    private var isValid: Bool {
        !newUsername.isEmpty &&
        newUsername.count >= 3 &&
        newUsername.count <= 20 &&
        newUsername != viewModel.username
    }

    private var validationError: String? {
        if newUsername.isEmpty {
            return nil
        } else if newUsername.count < 3 {
            return "Username must be at least 3 characters"
        } else if newUsername.count > 20 {
            return "Username must be 20 characters or less"
        } else if newUsername == viewModel.username {
            return "This is your current username"
        }
        return nil
    }

    private var characterCountColor: Color {
        if newUsername.count > 20 {
            return .lossRed
        } else if newUsername.count >= 3 {
            return .gainGreen
        } else {
            return .textSecondary
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text("Change Username")
                            .font(.headline1)
                            .foregroundColor(.textPrimary)

                        Text("Choose a unique username")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, Spacing.xl)

                    // Input Field
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("New Username")
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)

                            Spacer()

                            Text("\(newUsername.count)/20")
                                .font(.caption)
                                .foregroundColor(characterCountColor)
                        }

                        HStack(spacing: Spacing.sm) {
                            TextField("Username", text: $newUsername)
                                .textFieldStyle(ValidatedTextFieldStyle(isValid: validationError == nil && !newUsername.isEmpty))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            // Validation Icon
                            if !newUsername.isEmpty {
                                Image(systemName: validationError == nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(validationError == nil ? .gainGreen : .lossRed)
                                    .font(.title3)
                            }
                        }

                        if let error = validationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.lossRed)
                        } else if !newUsername.isEmpty && newUsername.count >= 3 {
                            Text("Looks good!")
                                .font(.caption)
                                .foregroundColor(.gainGreen)
                        }

                        // Helpful hints
                        if newUsername.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Username requirements:")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .padding(.top, Spacing.xxs)

                                ValidationRequirement(text: "3-20 characters", isMet: newUsername.count >= 3 && newUsername.count <= 20)
                                ValidationRequirement(text: "Letters, numbers, and underscores only", isMet: true)
                            }
                        }
                    }

                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.bodySmall)
                            .foregroundColor(.lossRed)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.lossRed.opacity(0.1))
                            .cornerRadius(Spacing.md)
                    }

                    // Save Button
                    PrimaryButton(title: "Save Username") {
                        Task {
                            await saveUsername()
                        }
                    }
                    .disabled(!isValid || isLoading)
                    .opacity(isValid && !isLoading ? 1.0 : 0.5)

                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }

    private func saveUsername() async {
        guard isValid else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await viewModel.updateUsername(newUsername)
            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }
}

struct ValidatedTextFieldStyle: TextFieldStyle {
    let isValid: Bool

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(Spacing.md)
            .foregroundColor(.textPrimary)
            .font(.bodyLarge)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.md)
                    .stroke(borderColor, lineWidth: 2)
            )
    }

    private var borderColor: Color {
        if isValid {
            return .gainGreen.opacity(0.5)
        } else {
            return .clear
        }
    }
}

struct ValidationRequirement: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isMet ? .gainGreen : .textMuted)

            Text(text)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    EditUsernameView(viewModel: ProfileViewModel())
}
