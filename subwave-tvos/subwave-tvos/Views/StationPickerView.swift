//
//  StationPickerView.swift
//  subwave-tvos
//

import SwiftUI

struct StationPickerView: View {
    @Bindable var store: StationStore
    @State private var isPresentingAddStation = false
    @State private var editingStation: Station?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.stations) { station in
                    Button {
                        store.selectedStationID = station.id
                    } label: {
                        stationRow(station)
                    }
                    // Long-press (Siri Remote's Menu/click-and-hold) is the
                    // tvOS way to surface secondary actions on a row whose
                    // primary tap already does something (select & play).
                    .contextMenu {
                        Button("Edit") { editingStation = station }
                        Button("Delete", role: .destructive) { store.removeStation(station) }
                    }
                }

                Button {
                    isPresentingAddStation = true
                } label: {
                    Label("Add Station", systemImage: "plus")
                }
            }
            .navigationTitle("SUB/WAVE Stations")
        }
        .sheet(isPresented: $isPresentingAddStation) {
            AddStationView(store: store)
        }
        .sheet(item: $editingStation) { station in
            AddStationView(store: store, editingStation: station)
        }
    }

    private func stationRow(_ station: Station) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(station.name)
                    .font(.headline)
                Text(station.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if station.id == store.selectedStationID {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
    }
}
