import Cache
import DomainTypes
import MockData
import SwiftUI

@available(iOS 27.1, *)
struct TwoColumnConditions: View {
    let surfEntry: SurfEntry

    @State private var isLandscape = false

    var body: some View {
        ArrangementView {
            List {
                Section("Wave") {
                    WaveRows(wave: surfEntry.wave)
                }

                if !isLandscape {
                    Section("Wind") {
                        WindRows(wind: surfEntry.wind)
                    }

                    Section {
                        LabeledContent(
                            "Updated",
                            value: surfEntry.date.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }
        } secondary: {
            List {
                Section("Wind") {
                    WindRows(wind: surfEntry.wind)
                }

                Section {
                    LabeledContent(
                        "Updated",
                        value: surfEntry.date.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .arrangementViewStyle(.split.axes(.horizontal))
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.width > proxy.size.height
        } action: {
            isLandscape = $0
        }
    }
}
