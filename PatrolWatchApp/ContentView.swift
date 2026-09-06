import SwiftUI
import DomainTypes
import MockData

enum Route: Hashable {
    case surfSpot(Place)
    case managePlaces
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SurfProvider.self) var surfProvider
    @State private var task: Task<Void, Never>?
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            PlacePicker(
                onSelect: { place in
                    path.append(.surfSpot(place))
                },
                onManagePlaces: {
                    path.append(.managePlaces)
                }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .surfSpot(let place):
                    SurfSpot(place: place)
                case .managePlaces:
                    ManagePlaces()
                }
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
