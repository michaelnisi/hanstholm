import SwiftUI
import DomainTypes
import Cache
import MockData

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
                        description: Text("Add the Hanstholm widget to your Lock Screen to fetch conditions.")
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
        List {
            Section("Wave") {
                LabeledContent("Height", value: surfEntry.wave.middle.feet())
                LabeledContent("Max", value: surfEntry.wave.max.feet())
                LabeledContent("Period", value: surfEntry.wave.period.seconds())
                LabeledContent("Direction", value: surfEntry.wave.direction.formatted())
            }

            Section("Wind") {
                LabeledContent("Speed", value: surfEntry.wind.speed.current.knots())
                LabeledContent("Gust", value: surfEntry.wind.speed.gust.knots())
                LabeledContent("Direction", value: surfEntry.wind.direction.formatted())
            }

            Section {
                LabeledContent("Updated", value: surfEntry.date.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle(surfEntry.place.name)
    }
}

#Preview {
    ConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
}

#Preview("No Data") {
    ContentUnavailableView(
        "No Data Yet",
        systemImage: "water.waves",
        description: Text("Add the Hanstholm widget to your Lock Screen to fetch conditions.")
    )
}
