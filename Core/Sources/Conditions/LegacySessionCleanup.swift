import Foundation

enum LegacySessionCleanup {
    static let sessionIdentifier = "hyde.dk"
    static let appGroup = "group.ink.codes.Patrol"
    static let defaultsKey = "ink.codes.Patrol.Conditions.didFlushLegacySession"

    static func flushIfNeeded(
        defaults: UserDefaults? = UserDefaults(suiteName: LegacySessionCleanup.appGroup)
    ) async {
        guard let defaults, !defaults.bool(forKey: defaultsKey) else {
            return
        }

        defaults.set(true, forKey: defaultsKey)

        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)

        for task in await session.allTasks {
            task.cancel()
        }

        session.invalidateAndCancel()
    }
}
