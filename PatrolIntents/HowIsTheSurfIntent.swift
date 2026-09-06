import AppIntents
import DomainTypes
import Conditions
import os.log

nonisolated let intentsLogger = Logger(subsystem: "ink.codes.Patrol", category: "Intents")

struct HowIsTheSurfIntent: AppIntent {
    static let title: LocalizedStringResource = "How Is The Surf"
    static let description = IntentDescription(
        "Reports current wind and wave conditions for your selected surf spot."
    )

    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let entry = try await ConditionsCoordinator.app.conditions(
                policy: .cached(maxAge: 5 * 60),
                trigger: .userInterface
            )

            return .result(dialog: IntentDialog(stringLiteral: entry.spokenSummary))
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            intentsLogger.error("how is the surf intent failed: \(error)")

            return .result(dialog: "I couldn't get surf conditions right now.")
        }
    }
}
