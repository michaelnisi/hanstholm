import WidgetKit
import Conditions
import Hyde

extension ConditionsCoordinator {
    nonisolated static let app = ConditionsCoordinator(
        configuration: .init(
            plugins: [Hyde()],
            deferredDownloads: nil,
            reloadWidgetTimelines: {
                WidgetCenter.shared.reloadAllTimelines()
            }
        )
    )
}
