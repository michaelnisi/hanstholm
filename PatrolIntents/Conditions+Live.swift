import Conditions
import Hyde
import WidgetKit

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
