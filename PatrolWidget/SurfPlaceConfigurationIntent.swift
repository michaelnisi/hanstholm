import AppIntents

struct SurfPlaceConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Surf Spot"
    static let description = IntentDescription(
        "Choose the surf spot this widget reports on. Leave it empty to follow the spot selected in the app."
    )

    @Parameter(title: "Surf Spot")
    var place: PlaceEntity?

    init() {}

    init(place: PlaceEntity) {
        self.place = place
    }
}
