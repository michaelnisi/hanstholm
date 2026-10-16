import AppIntents
import Conditions

struct SelectPlaceIntent: AppIntent {
    static let title: LocalizedStringResource = "Select Surf Spot"
    static let description = IntentDescription(
        "Switches the surf spot Patrol reports on."
    )

    @Parameter(title: "Surf Spot")
    var place: PlaceEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Switch to \(\.$place)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await ConditionsCoordinator.shared.selectPlace(place.place)

        return .result(dialog: "Switched to \(place.place.name).")
    }
}
