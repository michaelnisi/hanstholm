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
        ScrollView {
            if horizontalSizeClass == .regular {
                HStack(alignment: .top, spacing: 24) {
                    GroupedSection("Wave") {
                        WaveRows(wave: surfEntry.wave)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 24) {
                        GroupedSection("Wind") {
                            WindRows(wind: surfEntry.wind)
                        }

                        GroupedSection {
                            UpdatedRow(date: surfEntry.date)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            } else {
                VStack(spacing: 24) {
                    GroupedSection("Wave") {
                        WaveRows(wave: surfEntry.wave)
                    }

                    GroupedSection("Wind") {
                        WindRows(wind: surfEntry.wind)
                    }

                    GroupedSection {
                        UpdatedRow(date: surfEntry.date)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(surfEntry.place.name)
    }
}

private struct GroupedSection<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct WaveRows: View {
    let wave: SurfEntry.Wave

    var body: some View {
        VStack(spacing: 0) {
            LabeledContent("Height", value: wave.middle.feet())
                .padding(.vertical, 8)
            Divider()
            LabeledContent("Max", value: wave.max.feet())
                .padding(.vertical, 8)
            Divider()
            LabeledContent("Period", value: wave.period.seconds())
                .padding(.vertical, 8)
            Divider()
            LabeledContent("Direction", value: wave.direction.formatted())
                .padding(.vertical, 8)
        }
    }
}

private struct WindRows: View {
    let wind: SurfEntry.Wind

    var body: some View {
        VStack(spacing: 0) {
            LabeledContent("Speed", value: wind.speed.current.knots())
                .padding(.vertical, 8)
            Divider()
            LabeledContent("Gust", value: wind.speed.gust.knots())
                .padding(.vertical, 8)
            Divider()
            LabeledContent("Direction", value: wind.direction.formatted())
                .padding(.vertical, 8)
        }
    }
}

private struct UpdatedRow: View {
    let date: Date

    var body: some View {
        LabeledContent("Updated", value: date.formatted(date: .abbreviated, time: .shortened))
            .padding(.vertical, 8)
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
