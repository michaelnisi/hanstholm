import SwiftUI
import DomainTypes
import MockData

struct PlacePicker: View {
    let onSelect: (Place) -> Void

    @Environment(SurfProvider.self) private var surfProvider
    @State private var places: [Place] = []
    @State private var scrollPosition: Place.ID?
    @State private var bootstrapPlace: Place?

    private var selected: Place? {
        surfProvider.surfEntry?.place ?? bootstrapPlace
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(places) { place in
                        PlaceCard(place: place, isSelected: place.id == selected?.id) {
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
            .scrollPosition(id: $scrollPosition)
            .contentMargins(
                .bottom,
                max(0, (proxy.size.height - PlaceCard.height) / 2),
                for: .scrollContent
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            async let placesTask = surfProvider.availablePlaces()
            var bootstrap = surfProvider.surfEntry?.place
            if bootstrap == nil {
                bootstrap = await surfProvider.selectedPlace()
            }
            places = await placesTask
            bootstrapPlace = bootstrap
            scrollPosition = (bootstrap ?? places.first)?.id
        }
    }
}

#Preview {
    PlacePicker { _ in }
        .withMockProviders()
}
