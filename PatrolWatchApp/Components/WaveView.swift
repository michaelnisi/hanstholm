import SwiftUI
import DomainTypes
import MockData
import SurfUI

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
            DirectionIndicator(
                degrees: direction.degrees,
                formatted: direction.formatted(),
                spoken: direction.spoken()
            )

            middle.feetText()
                .font(.title2)
                .fontWeight(.bold)
            
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.black)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

#Preview {
    WaveView(name: "Hanstholm", date: .now, wave: MockData.SurfEntry.makeWave())
}
