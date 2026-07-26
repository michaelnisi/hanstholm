//
//  BackgroundRefresh.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 08.07.26.
//

import WatchKit
import Hyde
import DomainTypes
import Cache
import WidgetKit

func backgroundRefresh() async {
    let cache = Cache()
    let placeName = await cache.place()
    let place = Hyde.Place(name: placeName) ?? .hanstholm

    if let fresh = try? await Hyde.fetch(place: place), let entry = SurfEntry(dto: fresh) {
        try? await cache.setConditions(entry)
        WidgetCenter.shared.reloadAllTimelines()
    }

    scheduleBackgroundRefresh()
}

func scheduleBackgroundRefresh() {
    WKApplication.shared().scheduleBackgroundRefresh(
        withPreferredDate: .now.addingTimeInterval(15 * 60),
        userInfo: nil
    ) { _ in }
}
