import WatchKit
import Conditions

func backgroundRefresh() async {
    do {
        _ = try await ConditionsCoordinator.watchApp.conditions(
            policy: .reload,
            trigger: .appBackgroundRefresh
        )
    } catch {
        logger.error("background refresh failed: \(error)")
    }

    scheduleBackgroundRefresh()
}

func scheduleBackgroundRefresh() {
    WKApplication.shared().scheduleBackgroundRefresh(
        withPreferredDate: .now.addingTimeInterval(15 * 60),
        userInfo: nil
    ) { _ in }
}
