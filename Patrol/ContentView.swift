import SwiftUI
import DomainTypes
import Cache
import MockData
import SurfUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var surfEntry: SurfEntry?

    var body: some View {
        NavigationStack {
            Group {
                if let surfEntry {
                    ConditionsView(surfEntry: surfEntry)
                } else {
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "water.waves",
                        description: Text("Add the Patrol widget to your Lock Screen to fetch conditions.")
                    )
                }
            }
            .task {
                await load()
            }
            .onChange(of: scenePhase) {
                guard scenePhase == .active else {
                    return
                }

                Task {
                    await load()
                }
            }
        }
    }

    private func load() async {
        surfEntry = try? await Cache().selectedConditions()
    }
}

private struct ConditionsView: View {
    let surfEntry: SurfEntry

    var body: some View {
        VStack(spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) {
                    WaveGauge(wave: surfEntry.wave)
                    WindGauge(wind: surfEntry.wind)
                }
                VStack(spacing: 24) {
                    WaveGauge(wave: surfEntry.wave)
                    WindGauge(wind: surfEntry.wind)
                }
            }
            Text(surfEntry.date.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .fontDesign(.rounded)
        .navigationTitle(surfEntry.place.name)
    }
}

#Preview("Narrow") {
    NavigationStack {
        ConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
    }
    .frame(width: 300)
}

#Preview("Wide") {
    NavigationStack {
        ConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
    }
    .frame(width: 600)
}

#Preview("No Data") {
    ContentUnavailableView(
        "No Data Yet",
        systemImage: "water.waves",
        description: Text("Add the Patrol widget to your Lock Screen to fetch conditions.")
    )
}
