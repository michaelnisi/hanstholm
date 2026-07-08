//
//  BackgroundRefresh.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 08.07.26.
//

import WatchKit
import Hyde
import Cache
import WidgetKit

func backgroundRefresh() async {
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
