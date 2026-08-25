//
//  ContentView.swift
//  subwave-tvos
//
//  Created by Robin on 2026-08-25.
//

import SwiftUI

struct ContentView: View {
    @State private var store = StationStore()

    var body: some View {
        if let station = store.selectedStation {
            NavigationStack {
                NowPlayingView(station: station)
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            Button("Stations") { store.selectedStationID = nil }
                        }
                    }
            }
        } else {
            StationPickerView(store: store)
        }
    }
}

#Preview {
    ContentView()
}
