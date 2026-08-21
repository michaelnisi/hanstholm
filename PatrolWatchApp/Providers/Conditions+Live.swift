import WidgetKit
import Conditions
import Hyde

extension ConditionsCoordinator {
    nonisolated static let watchApp = ConditionsCoordinator(
        configuration: .init(
            plugins: [Hyde()],
            deferredDownloads: nil,
            reloadWidgetTimelines: {
                WidgetCenter.shared.reloadAllTimelines()
            }
        )
    )
}
