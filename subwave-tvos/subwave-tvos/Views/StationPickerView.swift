//
//  StationPickerView.swift
//  subwave-tvos
//

import SwiftUI

struct StationPickerView: View {
    @Bindable var store: StationStore
    @State private var isPresentingAddStation = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.stations) { station in
                    Button {
                        store.selectedStationID = station.id
                    } label: {
                        stationRow(station)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        store.removeStation(store.stations[index])
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
