import DomainTypes
import MockData
import SwiftUI

struct PlaceDetailView: View {
    let place: Place
    let entry: SurfEntry?

    var body: some View {
        Group {
            if let entry {
                OneColumnConditions(surfEntry: entry)
            } else {
                ContentUnavailableView(
                    "No Data Yet",
                    systemImage: "water.waves",
                    description: Text(
                        "Add the Patrol widget for \(place.name) to fetch conditions.")
                )
            }
        }
        .navigationTitle(place.name)
    }
}

#Preview {
    NavigationStack {
        PlaceDetailView(
            place: MockData.SurfEntry.makePlace(),
            entry: MockData.SurfEntry.makeSurfEntry()
        )
    }
}

#Preview("No Data") {
    NavigationStack {
        PlaceDetailView(place: MockData.SurfEntry.makePlace(), entry: nil)
    }
}
