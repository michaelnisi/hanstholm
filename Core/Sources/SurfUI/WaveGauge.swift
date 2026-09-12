import SwiftUI
import DomainTypes
import MockData

@MainActor
public struct WaveGauge: View {
    public var wave: SurfEntry.Wave
    public var strokeWidth: Double

    public init(wave: SurfEntry.Wave, strokeWidth: Double = 14) {
        self.wave = wave
        self.strokeWidth = strokeWidth
    }

    public var body: some View {
        SurfGauge(value: wave.middle, total: wave.max, tint: .blue, strokeWidth: strokeWidth) {
            GaugeReadout(
                symbol: "water.waves",
                value: wave.middle.feet(),
                caption: wave.period.seconds(),
                degrees: wave.direction.degrees
            )
        }
    }
}

#Preview {
    WaveGauge(wave: MockData.SurfEntry.makeWave())
}
