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
                    Text(place.name)
                }
                .onDelete(perform: delete)
            }
        }
        .task {
            included = await surfProvider.includedPlaces()
        }
    }

    private func delete(at offsets: IndexSet) {
        guard included.count > offsets.count else {
            return
        }

        included.remove(atOffsets: offsets)

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
