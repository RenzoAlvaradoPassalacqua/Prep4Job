import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    private let accountService: AccountService

    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showingFinalConfirm = false

    init(accountService: AccountService = AccountService()) {
        self.accountService = accountService
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isDeleting {
                        HStack {
                            ProgressView()
                            Text("Eliminando cuenta…")
                        }
                    } else {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Text("Eliminar cuenta")
                        }
                        .disabled(isDeleting)
                    }
                } header: {
                    Text("Cuenta")
                } footer: {
                    Text("Eliminar tu cuenta es permanente y no se puede deshacer.")
                }
            }
            .disabled(isDeleting)
            .navigationTitle("Ajustes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Label("Eliminar cuenta", systemImage: "trash")
                    }
                    .tint(.red)
                    .disabled(isDeleting)
                    .accessibilityLabel("Eliminar cuenta")
                }
            }
            .alert("¿Eliminar tu cuenta?", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    showingFinalConfirm = true
                }
            } message: {
                Text("Esta acción es permanente. Se borrarán tus datos y se cerrará la sesión.")
            }
            .alert("No se pudo eliminar la cuenta", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "Error desconocido.")
            })
            .confirmationDialog("Confirmar eliminación", isPresented: $showingFinalConfirm, titleVisibility: .visible) {
                Button("Sí, eliminar definitivamente", role: .destructive) { deleteAccount() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción eliminará tu cuenta y datos asociados.")
            }
        }
    }

    private func deleteAccount() {
        isDeleting = true
        Task {
            do {
                try await accountService.deleteAccount()
                isDeleting = false
                // Cerrar esta vista; el estado superior debería reaccionar a la pérdida de sesión.
                dismiss()
            } catch {
                isDeleting = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SettingsView()
}
