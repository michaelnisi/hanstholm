import AppIntents
import Conditions
import DomainTypes
import os.log

nonisolated let intentsLogger = Logger(subsystem: "ink.codes.Patrol", category: "Intents")

struct HowIsTheSurfIntent: AppIntent {
    static let title: LocalizedStringResource = "How Is The Surf"
    static let description = IntentDescription(
        "Reports current wind and wave conditions for the surf spot you name, or your default spot."
    )

    static let openAppWhenRun: Bool = false

    @Parameter(title: "Surf Spot")
    var place: PlaceEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("How is the surf at \(\.$place)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let policy = FreshnessPolicy.cached(maxAge: 5 * 60)

            let entry =
                if let place = place?.place {
                    try await ConditionsCoordinator.shared.conditions(
                        for: place,
                        policy: policy,
                        trigger: .userInterface
                    )
                } else {
                    try await ConditionsCoordinator.shared.conditions(
                        policy: policy,
                        trigger: .userInterface
                    )
                }

            return .result(dialog: IntentDialog(stringLiteral: entry.spokenSummary))
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            intentsLogger.error("how is the surf intent failed: \(error)")

            return .result(dialog: "I couldn't get surf conditions right now.")
        }
    }
}
