//
//  ClockView.swift
//  subwave-tvos
//
//  "Clock" panel — a plain analog clock in the station's own timezone, so a
//  glance at the side panel tells you what time it is *there*, which is what
//  the DJ's on-air time references (morning/afternoon/evening banter) are
//  actually keyed to.

import SwiftUI

struct ClockView: View {
    let timeZone: TimeZone?

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZone { calendar.timeZone = timeZone }
        return calendar
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let comps = calendar.dateComponents([.hour, .minute, .second], from: context.date)
            let hour = Double(comps.hour ?? 0)
            let minute = Double(comps.minute ?? 0)
            let second = Double(comps.second ?? 0)

            VStack(spacing: 20) {
                ClockFace(hour: hour, minute: minute, second: second)

                VStack(spacing: 4) {
                    Text(digitalTime(context.date))
                        .font(.title3.monospacedDigit())
                    if let name = timeZone?.identifier {
                        Text(name.replacingOccurrences(of: "_", with: " "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func digitalTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
}

private struct ClockFace: View {
    let hour: Double
    let minute: Double
    let second: Double

    /// All three hands share this one frame; only `length` (a fraction of
    /// its half-width) differs between them, so they share a single, honest
    /// notion of "the face's radius".
    private let diameter: CGFloat = 220

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(.secondary, lineWidth: 2)

            ForEach(0..<12) { tick in
                Rectangle()
                    .fill(.secondary)
                    .frame(width: 2, height: tick % 3 == 0 ? 14 : 8)
                    .offset(y: -(diameter / 2 - 8))
                    .rotationEffect(.degrees(Double(tick) / 12 * 360))
            }

            hand(angle: (hour.truncatingRemainder(dividingBy: 12) + minute / 60) / 12 * 360, length: 0.5, width: 5, color: .primary)
            hand(angle: (minute + second / 60) / 60 * 360, length: 0.75, width: 3, color: .primary)
            hand(angle: second / 60 * 360, length: 0.85, width: 1.5, color: .orange)

            Circle()
                .fill(.primary)
                .frame(width: 8, height: 8)
        }
        .frame(width: diameter, height: diameter)
    }

    private func hand(angle: Double, length: CGFloat, width: CGFloat, color: Color) -> some View {
        ClockHand(angle: .degrees(angle), length: length)
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
            .frame(width: diameter, height: diameter)
    }
}

/// A hand from the face's center out to `length` fraction of the enclosing
/// square's half-width, at `angle` measured clockwise from 12 o'clock.
private struct ClockHand: Shape {
    var angle: Angle
    var length: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * length
        let end = CGPoint(
            x: center.x + radius * sin(angle.radians),
            y: center.y - radius * cos(angle.radians)
        )
        var path = Path()
        path.move(to: center)
        path.addLine(to: end)
        return path
    }
}
