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
        ScrollView {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    GaugesColumn(surfEntry: surfEntry)
                    ConditionsDetails(surfEntry: surfEntry)
                        .frame(maxWidth: 400)
                    Spacer(minLength: 0)
                }
                VStack(spacing: 24) {
                    GaugesColumn(surfEntry: surfEntry)
                    ConditionsDetails(surfEntry: surfEntry)
                }
            }
            .padding()
        }
        .navigationTitle(surfEntry.place.name)
    }
}

private struct GaugesColumn: View {
    let surfEntry: SurfEntry

    var body: some View {
        VStack(spacing: 24) {
            WaveGauge(wave: surfEntry.wave)
            WindGauge(wind: surfEntry.wind)
        }
        .fontDesign(.rounded)
    }
}

private struct ConditionsDetails: View {
    let surfEntry: SurfEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailSection(title: "Wave") {
                LabeledContent("Height", value: surfEntry.wave.middle.feet())
                LabeledContent("Max", value: surfEntry.wave.max.feet())
                LabeledContent("Period", value: surfEntry.wave.period.seconds())
                LabeledContent("Direction", value: surfEntry.wave.direction.formatted())
            }

            DetailSection(title: "Wind") {
                LabeledContent("Speed", value: surfEntry.wind.speed.current.knots())
                LabeledContent("Gust", value: surfEntry.wind.speed.gust.knots())
                LabeledContent("Direction", value: surfEntry.wind.direction.formatted())
            }

            LabeledContent("Updated", value: surfEntry.date.formatted(date: .abbreviated, time: .shortened))
        }
        .frame(idealWidth: 320, maxWidth: .infinity, alignment: .leading)
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            VStack(spacing: 4) {
                content()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
    }
}

#Preview("No Data") {
    ContentUnavailableView(
        "No Data Yet",
        systemImage: "water.waves",
        description: Text("Add the Patrol widget to your Lock Screen to fetch conditions.")
    )
}
