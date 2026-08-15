import SwiftUI
import DomainTypes
import MockData

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SurfProvider.self) var surfProvider
    @State private var task: Task<Void, Never>?

    var body: some View {
        Group {
            if let surfEntry = surfProvider.surfEntry {
                SurfSpot(surfEntry: surfEntry)
            } else if let lastError = surfProvider.lastError {
                ContentUnavailableView {
                    Label("Couldn't Load Conditions", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(lastError.localizedDescription)
                } actions: {
                    Button("Retry") {
                        Task { await surfProvider.load() }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            await surfProvider.load()
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                task = Task {
                    await surfProvider.load()
                }
                scheduleBackgroundRefresh()
            case .background, .inactive:
                task?.cancel()
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
        .withMockProviders()
}

#Preview("Error") {
    ContentView()
        .environment(
            SurfProvider(dependencies: .init(
                cachedEntry: { nil },
                fetchEntry: { throw URLError(.notConnectedToInternet) },
                availablePlaces: { [] },
                selectPlace: { _ in }
            ))
        )
}
