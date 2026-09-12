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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let surfEntry: SurfEntry

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                CompactConditionsView(surfEntry: surfEntry)
            } else {
                RegularConditionsView(surfEntry: surfEntry)
            }
        }
        .navigationTitle(surfEntry.place.name)
    }
}

private struct CompactConditionsView: View {
    let surfEntry: SurfEntry

    var body: some View {
        VStack(spacing: 12) {
            WaveGauge(wave: surfEntry.wave)
                .overlay(alignment: .bottom) {
                    Text("\(surfEntry.wind.direction.formatted()) \(surfEntry.wind.speed.current.knots())")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            Text(surfEntry.date.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .fontDesign(.rounded)
    }
}

private struct RegularConditionsView: View {
    let surfEntry: SurfEntry

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                WaveGauge(wave: surfEntry.wave)
                WindGauge(wind: surfEntry.wind)
            }
            Text(surfEntry.date.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .fontDesign(.rounded)
    }
}

#Preview("Compact") {
    CompactConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
}

#Preview("Regular") {
    RegularConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
}

#Preview("No Data") {
    ContentUnavailableView(
        "No Data Yet",
        systemImage: "water.waves",
        description: Text("Add the Patrol widget to your Lock Screen to fetch conditions.")
    )
}
