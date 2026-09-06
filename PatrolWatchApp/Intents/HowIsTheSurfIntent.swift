import AppIntents
import DomainTypes
import Conditions

struct HowIsTheSurfIntent: AppIntent {
    static let title: LocalizedStringResource = "How Is The Surf"
    static let description = IntentDescription(
        "Reports current wind and wave conditions for your selected surf spot."
    )

    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let entry = try await ConditionsCoordinator.watchApp.conditions(
                policy: .cached(maxAge: 5 * 60),
                trigger: .userInterface
            )

            return .result(dialog: IntentDialog(stringLiteral: entry.spokenSummary))
        } catch {
            logger.error("how is the surf intent failed: \(error)")

            return .result(dialog: "I couldn't get surf conditions right now.")
        }
    }
}

extension SurfEntry {
    var spokenSummary: String {
        "At \(place.name), wind is \(wind.speed.current.knots(width: .wide)) from \(wind.direction.formatted()), and waves are \(wave.middle.feet()) at \(wave.period.seconds(width: .wide)) from \(wave.direction.formatted())."
    }
}
