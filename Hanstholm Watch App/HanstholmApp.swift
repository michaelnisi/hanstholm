//
//  HanstholmApp.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 14.04.24.
//

import SwiftUI
import WatchKit
import Hyde
import Cache
import WidgetKit
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
            scheduleBackgroundRefresh()
        }
    }
}

private func backgroundRefresh() async {
    let cache = Cache()
    let place = await cache.place()

    guard let fresh = try? await Hyde.fetch(place: place) else {
        return
    }

    try? await cache.setConditions(fresh)
    WidgetCenter.shared.reloadAllTimelines()
}

func scheduleBackgroundRefresh() {
    WKApplication.shared().scheduleBackgroundRefresh(
        withPreferredDate: .now.addingTimeInterval(15 * 60),
        userInfo: nil
    ) { _ in }
}
