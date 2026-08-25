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
            NowPlayingView(station: station) {
                store.selectedStationID = nil
            }
        } else {
            StationPickerView(store: store)
        }
    }
}

#Preview {
    ContentView()
}
