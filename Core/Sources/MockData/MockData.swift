//
//  MockData.swift
//
//
//  Created by Michael Nisi on 11.05.24.
//

import Foundation
import DomainTypes

public struct MockData {
    public struct SurfEntry {
        public static func makeSurfEntry() -> DomainTypes.SurfEntry {
            .init(
                date: .now,
                name: "Hanstholm",
                status: .ok,
                wave: .init(max: 2.0, middle: 1.2, period: 12),
                wind: .init(speed: 20, direction: .init(cardinal: .southWest))
            )
        }
    }
}
