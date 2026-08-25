//
//  AddStationView.swift
//  subwave-tvos
//

import SwiftUI

struct AddStationView: View {
    @Bindable var store: StationStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""
    @State private var validationError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("My Station", text: $name)
                }
                Section("Address") {
                    TextField("radio.example.com", text: $address)
                        .autocorrectionDisabled()
                    Text("For a private station, include the shared password: dj:secret@radio.example.com")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let validationError {
                    Text(validationError)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Add Station")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || address.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        guard ResolvedAddress(typedAddress: address) != nil else {
            validationError = "That doesn't look like a valid address."
            return
        }
        store.addStation(name: name.trimmingCharacters(in: .whitespaces), address: address.trimmingCharacters(in: .whitespaces))
        dismiss()
    }
}
