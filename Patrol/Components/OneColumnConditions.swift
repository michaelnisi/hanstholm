import Cache
import DomainTypes
import MockData
import SwiftUI

struct OneColumnConditions: View {
    let surfEntry: SurfEntry

    var body: some View {
        List {
            Section("Wave") {
                WaveRows(wave: surfEntry.wave)
            }

            Section("Wind") {
                WindRows(wind: surfEntry.wind)
            }

            Section {
                LabeledContent(
                    "Updated", value: surfEntry.date.formatted(date: .abbreviated, time: .shortened)
                )
            }
        }
    }
}
