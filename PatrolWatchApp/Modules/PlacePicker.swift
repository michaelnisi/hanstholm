import SwiftUI
import DomainTypes
import MockData

struct PlacePicker: View {
    /// Vertical gap between cards. Small enough that the neighbouring cards
    /// peek in above and below the centered one.
    private static let cardSpacing: CGFloat = 12

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
            ScrollView(.vertical) {
                LazyVStack(spacing: Self.cardSpacing) {
                    ForEach(places) { place in
                        PlaceCard(place: place, isSelected: place.id == selected?.id) {
                            onSelect(place)
                        }
                        // Interactive rather than phase-based, so a card grows
                        // and brightens continuously as it approaches the
                        // center instead of popping once it gets there.
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            content
                                .scaleEffect(1 - abs(phase.value) * 0.15)
                                .opacity(1 - abs(phase.value) * 0.6)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            // Padding the content by half the leftover height at both ends is
            // what lets the first and last card reach the middle of the
            // screen; `.viewAligned` then snaps the nearest card into that
            // now-centered aligned position.
            .contentMargins(
                .vertical,
                Self.centeringInset(forHeight: proxy.size.height),
                for: .scrollContent
            )
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollPosition)
        }
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

    private static func centeringInset(forHeight height: CGFloat) -> CGFloat {
        max(0, (height - PlaceCard.height) / 2)
    }
}

#Preview {
    PlacePicker { _ in }
        .withMockProviders()
}
