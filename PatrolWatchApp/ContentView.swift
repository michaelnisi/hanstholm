import SwiftUI
import DomainTypes
import MockData

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SurfProvider.self) var surfProvider
    @State private var task: Task<Void, Never>?
    @State private var path: [Place] = []

    var body: some View {
        NavigationStack(path: $path) {
            PlacePicker { place in
                path.append(place)
            }
            .navigationDestination(for: Place.self) { place in
                SurfSpot(place: place)
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
