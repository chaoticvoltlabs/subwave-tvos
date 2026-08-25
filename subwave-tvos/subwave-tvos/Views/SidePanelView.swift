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
        // A segmented Picker above a List reliably trapped focus inside the
        // list on tvOS — scrolling past the first row never handed focus
        // back up to the picker (confirmed on-device, not just simulator
        // guesswork). TabView is tvOS's native top-tab-bar idiom and gets
        // correct up/down-to-tab-bar focus handling for free. Trade-off:
        // TabView keeps every tab's content alive rather than instantiating
        // only the selected one, so Booth and Guide now poll continuously
        // regardless of which tab is showing, not just while visible — an
        // acceptable cost at 10s/300s intervals for remote navigation that
        // actually works.
        TabView(selection: Binding(
            get: { selection },
            set: { selectionRaw = $0.rawValue }
        )) {
            ForEach(SidePanel.allCases) { panel in
                content(for: panel)
                    .tabItem { Label(panel.rawValue, systemImage: panel.systemImage) }
                    .tag(panel)
            }
        }
    }

    @ViewBuilder
    private func content(for panel: SidePanel) -> some View {
        switch panel {
        case .booth:
            BoothView(client: client)
        case .guide:
            ScheduleGuideView(client: client, stationTimeZone: stationTimeZone)
        case .clock:
            ClockView(timeZone: stationTimeZone)
        }
    }
}
