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
            VStack {
                wave.middle.feetText()
                    .font(.title2)
                    .fontWeight(.black)

                Text(wave.period.seconds())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .cappedDynamicType()
            }
        }
        .overlay(alignment: .bottom) {
            DirectionIndicator(direction: wave.direction)
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
