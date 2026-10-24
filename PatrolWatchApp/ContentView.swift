import DomainTypes
import MockData
import SwiftUI

enum Route: Hashable {
    case surfSpot(Place)
    case managePlaces
    case addPlace
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
                case .addPlace:
                    AddPlace()
                }
            }
        }
        .task {
            await surfProvider.load()
        }
        .onOpenURL { url in
            Task {
                await open(url)
            }
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

    private func open(_ url: URL) async {
        guard let id = PlaceID(url: url),
            let place = await surfProvider.availablePlaces().first(where: { $0.id == id })
        else {
            logger.error("unknown place link: \(url, privacy: .public)")
            return
        }

        path = [.surfSpot(place)]
    }
}

#Preview {
    ContentView()
        .withMockProviders()
}
