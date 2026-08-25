//
//  SidePanelView.swift
//  subwave-tvos
//

import SwiftUI

enum SidePanel: String, CaseIterable, Identifiable {
    case booth = "Booth"
    case guide = "Guide"
    case clock = "Clock"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .booth: return "mic"
        case .guide: return "calendar"
        case .clock: return "clock"
        }
    }
}

struct SidePanelView: View {
    let client: SubwaveClient
    let stationTimeZone: TimeZone?

    /// Remembered across stations/launches — whichever panel a listener
    /// picks is probably the one they want by default next time too.
    @AppStorage("subwave.sidePanel") private var selectionRaw = SidePanel.booth.rawValue

    private var selection: SidePanel {
        SidePanel(rawValue: selectionRaw) ?? .booth
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Panel", selection: Binding(
                get: { selection },
                set: { selectionRaw = $0.rawValue }
            )) {
                ForEach(SidePanel.allCases) { panel in
                    Label(panel.rawValue, systemImage: panel.systemImage).tag(panel)
                }
            }
            .pickerStyle(.segmented)

            // Only the active panel is instantiated, so switching away stops
            // its polling for free via the normal .task/.onDisappear lifecycle.
            switch selection {
            case .booth:
                BoothView(client: client)
            case .guide:
                ScheduleGuideView(client: client, stationTimeZone: stationTimeZone)
            case .clock:
                ClockView(timeZone: stationTimeZone)
            }
        }
    }
}
