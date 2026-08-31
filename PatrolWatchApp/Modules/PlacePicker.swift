import SwiftUI
import DomainTypes
import MockData

struct PlacePicker: View {
    private static let cardSpacing: CGFloat = 12

    let onSelect: (Place) -> Void

    @Environment(SurfProvider.self) private var surfProvider
    @ScaledMetric private var cardHeight: CGFloat = PlaceCard.baseHeight
    @State private var places: [Place] = []
    @State private var scrollPosition: Place.ID?
    @State private var bootstrapPlace: Place?
    @State private var containerHeight: CGFloat = 0

    private var selected: Place? {
        surfProvider.surfEntry?.place ?? bootstrapPlace
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: Self.cardSpacing) {
                ForEach(places) { place in
                    PlaceCard(place: place, isSelected: place.id == selected?.id) {
                        onSelect(place)
                    }
                    .scrollTransition(.interactive, axis: .vertical) { content, phase in
                        content
                            .scaleEffect(1 - abs(phase.value) * 0.15)
                            .opacity(1 - abs(phase.value) * 0.6)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newHeight in
            containerHeight = newHeight
        }
        .contentMargins(
            .vertical,
            centeringInset(forHeight: containerHeight),
            for: .scrollContent
        )
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition)
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

    private func centeringInset(forHeight height: CGFloat) -> CGFloat {
        max(0, (height - cardHeight) / 2)
    }
}

#Preview {
    PlacePicker { _ in }
        .withMockProviders()
}
