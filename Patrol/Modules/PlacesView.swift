import DomainTypes
import SwiftUI

struct PlacesView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var model: PlacesModel
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar

    init(model: PlacesModel = .live) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model

        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            List(model.places, selection: $model.selection) { place in
                PlaceRow(place: place, entry: model.entries[place.id])
            }
            .navigationTitle("Places")
        } detail: {
            if let place = model.selectedPlace {
                PlaceDetailView(
                    place: place,
                    entry: model.entries[place.id],
                    phase: model.phase(for: place),
                    onRefresh: {
                        await model.refresh(place, policy: PlacesModel.pullToRefreshPolicy)
                    }
                )
                .task(id: place.id) {
                    await model.refresh(place)
                }
            } else {
                ContentUnavailableView("Select a Place", systemImage: "water.waves")
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

                if let place = model.selectedPlace {
                    await model.refresh(place)
                }
            }
        }
    }

    private func load() async {
        await model.load()

        if horizontalSizeClass == .regular {
            await model.preselectAppSelection()
        }
    }
}

struct PlaceRow: View {
    let place: Place
    let entry: SurfEntry?

    var body: some View {
        VStack(alignment: .leading) {
            Text(place.name)

            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var summary: String {
        guard let entry else {
            return "No data"
        }

        return "\(entry.wave.middle.feet()) @ \(entry.wave.period.seconds())"
    }
}

#Preview {
    PlacesView(model: .mock)
}

#Preview("Regular") {
    PlacesView(model: .mock)
        .environment(\.horizontalSizeClass, .regular)
}
