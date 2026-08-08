import SwiftUI
import MockData
import os.log

nonisolated let logger = Logger(subsystem: "ink.codes.hanstholm", category: "App")

@main
struct Hanstholm_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SurfProvider.live)
        }
        .backgroundTask(.appRefresh("ink.codes.Hanstholm")) {
            await backgroundRefresh()
        }
    }
}
