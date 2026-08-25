import SwiftUI
import DomainTypes
import MockData

struct PlacePicker: View {
    let selected: Place
    let onSelect: (Place) -> Void

    @Environment(SurfProvider.self) private var surfProvider
    @State private var places: [Place] = []
    @State private var scrollPosition: Place.ID?
    @State private var expandedPlace: Place?
    @State private var selectionTask: Task<Void, Never>?
    @Namespace private var cardNamespace

    private static let settleDelay = Duration.seconds(1)
    private static let holdDelay = Duration.seconds(0.6)

    var body: some View {
        NavigationStack {
            Group {
                if let expandedPlace {
                    PlaceCard(place: expandedPlace, isSelected: true, isExpanded: true)
                        .matchedGeometryEffect(id: expandedPlace.id, in: cardNamespace)
                        .ignoresSafeArea()
                } else {
                    GeometryReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(places) { place in
                                    PlaceCard(place: place, isSelected: place.id == selected.id)
                                        .matchedGeometryEffect(id: place.id, in: cardNamespace)
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
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                places = await surfProvider.availablePlaces()
                scrollPosition = selected.id
            }
            .onChange(of: scrollPosition) { _, settledID in
                selectionTask?.cancel()
                guard let settledID, settledID != selected.id,
                      let place = places.first(where: { $0.id == settledID }) else { return }
                selectionTask = Task {
                    try? await Task.sleep(for: Self.settleDelay)
                    guard !Task.isCancelled else { return }
                    withAnimation(.snappy, completionCriteria: .logicallyComplete) {
                        expandedPlace = place
                    } completion: {
                        Task {
                            try? await Task.sleep(for: Self.holdDelay)
                            onSelect(place)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PlacePicker(selected: MockData.SurfEntry.makePlace()) { _ in }
        .withMockProviders()
}
