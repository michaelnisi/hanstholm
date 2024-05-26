//
//  MockData+Hyde.swift
//
//
//  Created by Michael Nisi on 12.05.24.
//

import Foundation
import Hyde

extension MockData {
    public struct HydeAPI {
        public static func makeHyde() -> Hyde {
            .init(
                place: .hanstholm,
                date: .now,
                wave: .init(height: .init(max: 2, middle: 1.2), period: 8, direction: "NØ"),
                wind: .init(speed: .init(gust: 15, middle: 7, current: 8), direction: "SV")
            )
        }
    }
}
