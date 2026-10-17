import DomainTypes
import MockData
import SwiftUI

struct PlaceDetailView: View {
    let place: Place
    let entry: SurfEntry?
    let phase: PlacesModel.Phase
    let onRefresh: () async -> Void

    var body: some View {
        Group {
            if let entry {
                OneColumnConditions(surfEntry: entry)
                    .refreshable {
                        await onRefresh()
                    }
            } else if phase == .failed {
                ContentUnavailableView {
                    Label("Couldn't Load Conditions", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("Conditions for \(place.name) aren't available right now.")
                } actions: {
                    Button("Try Again") {
                        Task {
                            await onRefresh()
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(place.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if phase == .loading, entry != nil {
                    ProgressView()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlaceDetailView(
            place: MockData.SurfEntry.makePlace(),
            entry: MockData.SurfEntry.makeSurfEntry(),
            phase: .idle,
            onRefresh: {}
        )
    }
}

#Preview("Refreshing") {
    NavigationStack {
        PlaceDetailView(
            place: MockData.SurfEntry.makePlace(),
            entry: MockData.SurfEntry.makeSurfEntry(),
            phase: .loading,
            onRefresh: {}
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        PlaceDetailView(
            place: MockData.SurfEntry.makePlace(),
            entry: nil,
            phase: .loading,
            onRefresh: {}
        )
    }
}

#Preview("Failed") {
    NavigationStack {
        PlaceDetailView(
            place: MockData.SurfEntry.makePlace(),
            entry: nil,
            phase: .failed,
            onRefresh: {}
        )
    }
}
