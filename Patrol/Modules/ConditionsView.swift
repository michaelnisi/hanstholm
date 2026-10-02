import SwiftUI
import DomainTypes
import MockData

struct ConditionsView: View {
    let surfEntry: SurfEntry

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if #available(iOS 27.1, *), horizontalSizeClass == .regular {
                TwoColumnConditions(surfEntry: surfEntry)
            } else {
                OneColumnConditions(surfEntry: surfEntry)
            }
        }
        .navigationTitle(surfEntry.place.name)
    }
}

#Preview {
    ConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
}

#Preview("Two Column") {
    ConditionsView(surfEntry: MockData.SurfEntry.makeSurfEntry())
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("No Data") {
    ContentUnavailableView(
        "No Data Yet",
        systemImage: "water.waves",
        description: Text("Add the Patrol widget to your Lock Screen to fetch conditions.")
    )
}
