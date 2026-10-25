import DomainTypes
import MockData
import SurfUI
import SwiftUI

struct WaveView: View {
    let name: String
    let date: Date
    let wave: SurfEntry.Wave

    var body: some View {
        SurfGauge(value: wave.middle, total: wave.max, tint: .blue) {
            WaveInfo(
                date: date,
                max: wave.max,
                middle: wave.middle,
                period: wave.period,
                direction: wave.direction
            )
        }
        .overlay(alignment: .bottom) {
            Text("\(wave.period.seconds(width: .narrow))")
                .font(.headline)
                .cappedDynamicType()
        }
        .fontDesign(.rounded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        "\(name). \(wave.spoken). Updated \(date.formatted(date: .omitted, time: .shortened))."
    }
}

struct WaveInfo: View {
    let date: Date
    let max: Double
    let middle: Double
    let period: Double
    let direction: Direction

    var body: some View {
        VStack {
            HStack {
                DirectionIndicator(
                    degrees: direction.degrees,
                    formatted: direction.formatted()
                )
                Text(direction.formatted())
                    .font(.caption2)
            }

            middle.feetText().font(.title2)
                .font(.title2)
                .fontWeight(.bold)

            TimestampCaption(date: date)
        }
        .padding()
        .cappedDynamicType()
    }
}

#Preview {
    WaveInfo(
        date: .now,
        max: 1.4,
        middle: 0.9,
        period: 7,
        direction: Direction(cardinal: .westNorthWest)
    )
    .padding()
    .background(Color.accentColor.gradient)
}

#Preview {
    WaveView(name: "Hanstholm", date: .now, wave: MockData.SurfEntry.makeWave())
}
