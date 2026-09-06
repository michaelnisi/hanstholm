import SwiftUI
import DomainTypes
import MockData

struct ManagePlaces: View {
    @Environment(SurfProvider.self) private var surfProvider
    @State private var included: [Place] = []

    var body: some View {
        List {
            Section {
                NavigationLink(value: Route.addPlace) {
                    Label("Add Place", systemImage: "plus")
                }
            }
            Section("Places") {
                ForEach(included) { place in
                    Label(place.name, systemImage: place.icon)
                        .swipeActions(edge: .trailing) {
                            if included.count > 1 {
                                Button(role: .destructive) {
                                    delete(place)
                                } label: {
                                    Image(systemName: "xmark")
                                }
                            }
                        }
                }
            }
        }
        .task {
            included = await surfProvider.includedPlaces()
        }
    }

    private func delete(_ place: Place) {
        guard included.count > 1 else {
            return
        }

        included.removeAll { $0.id == place.id }

        Task {
            await surfProvider.setIncludedPlaceIDs(included.map(\.id))
        }
    }
}

#Preview {
    NavigationStack {
        ManagePlaces()
            .withMockProviders()
    }
}
