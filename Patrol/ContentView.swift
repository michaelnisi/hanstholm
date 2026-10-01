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
                TwoColumnConditions(surfEntry: surfEntry)
            } else {
                OneColumnConditions(surfEntry: surfEntry)
            }
        }
        .navigationTitle(surfEntry.place.name)
    }
}

#Preview {
    ConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
}

#Preview("Two Column") {
    ConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("No Data") {
    ContentUnavailableView(
        "No Data Yet",
        systemImage: "water.waves",
        description: Text("Add the Patrol widget to your Lock Screen to fetch conditions.")
    )
}
