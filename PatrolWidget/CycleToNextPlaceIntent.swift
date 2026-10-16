#if !os(watchOS)
import AppIntents
import Conditions

struct CycleToNextPlaceIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Surf Spot"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await ConditionsCoordinator.widget.selectNextPlace()

        return .result()
    }
}
#endif
