import SwiftUI
import DomainTypes
import MockData

struct ManagePlaces: View {
    @Environment(SurfProvider.self) private var surfProvider
    @State private var included: [Place] = []
    @State private var excluded: [Place] = []

    var body: some View {
        List {
            Section("Included") {
                ForEach(included) { place in
                    Toggle(place.name, isOn: includedBinding(for: place))
                        .disabled(included.count == 1)
                }
                .onMove(perform: move)
            }
            Section("Available") {
                ForEach(excluded) { place in
                    Toggle(place.name, isOn: includedBinding(for: place))
                }
            }
        }
        .navigationTitle("Manage Places")
        .task {
            await load()
        }
    }

    private func includedBinding(for place: Place) -> Binding<Bool> {
        Binding(
            get: { included.contains { $0.id == place.id } },
            set: { isIncluded in
                if isIncluded {
                    include(place)
                } else {
                    exclude(place)
                }
            }
        )
    }

    private func include(_ place: Place) {
        excluded.removeAll { $0.id == place.id }
        included.append(place)
        persist()
    }

    private func exclude(_ place: Place) {
        guard included.count > 1 else {
            return
        }

        included.removeAll { $0.id == place.id }
        excluded.append(place)
        persist()
    }

    private func move(from source: IndexSet, to destination: Int) {
        included.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    private func persist() {
        Task {
            await surfProvider.setIncludedPlaceIDs(included.map(\.id))
        }
    }

    private func load() async {
        let all = await surfProvider.availablePlaces()
        let includedPlaces = await surfProvider.includedPlaces()
        let includedIDs = Set(includedPlaces.map(\.id))

        included = includedPlaces
        excluded = all.filter { !includedIDs.contains($0.id) }
    }
}

#Preview {
    NavigationStack {
        ManagePlaces()
            .withMockProviders()
    }
}
