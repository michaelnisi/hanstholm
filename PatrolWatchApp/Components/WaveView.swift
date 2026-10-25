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
                directionDegrees: wave.direction.degrees,
                directionLabel: wave.direction.formatted()
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

#Preview {
    WaveView(name: "Hanstholm", date: .now, wave: MockData.SurfEntry.makeWave())
}
