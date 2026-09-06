import SwiftUI
import DomainTypes
import MockData

struct AddPlace: View {
    @Environment(SurfProvider.self) private var surfProvider
    @Environment(\.dismiss) private var dismiss
    @State private var excluded: [Place] = []

    var body: some View {
        List(excluded) { place in
            Button {
                add(place)
            } label: {
                Label(place.name, systemImage: place.icon)
            }
        }
        .navigationTitle("Add Place")
        .task {
            await load()
        }
    }

    private func load() async {
        let all = await surfProvider.availablePlaces()
        let includedIDs = Set(await surfProvider.includedPlaces().map(\.id))

        excluded = all.filter { !includedIDs.contains($0.id) }
    }

    private func add(_ place: Place) {
        Task {
            let included = await surfProvider.includedPlaces()
            await surfProvider.setIncludedPlaceIDs(included.map(\.id) + [place.id])
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        AddPlace()
            .withMockProviders()
    }
}
