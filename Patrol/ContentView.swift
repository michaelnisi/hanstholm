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
        surfEntry = await Cache().selectedConditions()
    }
}

private struct ConditionsView: View {
    let surfEntry: SurfEntry

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack {
                    List {
                        Section("Wave") {
                            WaveRows(wave: surfEntry.wave)
                        }
                    }

                    List {
                        Section("Wind") {
                            WindRows(wind: surfEntry.wind)
                        }

                        Section {
                            LabeledContent("Updated", value: surfEntry.date.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
            } else {
                List {
                    Section("Wave") {
                        WaveRows(wave: surfEntry.wave)
                    }

                    Section("Wind") {
                        WindRows(wind: surfEntry.wind)
                    }

                    Section {
                        LabeledContent("Updated", value: surfEntry.date.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }
        }
        .navigationTitle(surfEntry.place.name)
    }
}

private struct WaveRows: View {
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

private struct WindRows: View {
    let wind: SurfEntry.Wind

    var body: some View {
        Group {
            LabeledContent("Speed", value: wind.speed.current.knots())
            LabeledContent("Gust", value: wind.speed.gust.knots())
            LabeledContent("Direction", value: wind.direction.formatted())
        }
    }
}

#Preview {
    ConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
}

#Preview("Two Column") {
    ConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
        .environment(\.horizontalSizeClass, .regular)
        .previewLayout(.fixed(width: 1000, height: 500))
}

#Preview("No Data") {
    ContentUnavailableView(
        "No Data Yet",
        systemImage: "water.waves",
        description: Text("Add the Patrol widget to your Lock Screen to fetch conditions.")
    )
}
