import DomainTypes
import SwiftUI

struct WaveRows: View {
    let wave: SurfEntry.Wave

    var body: some View {
        Group {
            LabeledContent("Height", value: wave.middle.feet())
            LabeledContent("Max", value: wave.max.feet())
            LabeledContent("Period", value: wave.period.seconds())
            LabeledContent("Direction", value: wave.direction.formatted())
        }
    }
}
