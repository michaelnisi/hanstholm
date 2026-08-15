import SwiftUI
import DomainTypes
import MockData

struct PlacePicker: View {
    let selected: Place
    let onSelect: (Place) -> Void

    @Environment(SurfProvider.self) private var surfProvider
    @State private var places: [Place] = []

    var body: some View {
        NavigationStack {
            List(places) { place in
                Button {
                    onSelect(place)
                } label: {
                    HStack {
                        Text(place.name)
                        if place.id == selected.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Places")
            .task {
                places = await surfProvider.availablePlaces()
            }
        }
    }
}

#Preview {
    PlacePicker(selected: MockData.SurfEntry.makePlace()) { _ in }
        .withMockProviders()
}
