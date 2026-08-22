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
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(places) { place in
                        PlaceCard(place: place, isSelected: place.id == selected.id) {
                            onSelect(place)
                        }
                        .scrollTransition { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.85)
                                .opacity(phase.isIdentity ? 1 : 0.4)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
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
