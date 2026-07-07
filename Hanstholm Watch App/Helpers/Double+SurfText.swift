//
//  Double+SurfText.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 07.07.26.
//

import SwiftUI
import Foundation

extension Double {
    func feetText(unitFont: Font = .caption) -> Text {
        let converted = Measurement<UnitLength>(value: self, unit: .meters).converted(to: .feet)
        let value = Int(ceil(converted.value))
        return Text("\(value)\(Text("ft").font(unitFont))")
    }

    func knotsText(unitFont: Font = .caption) -> Text {
        let converted = Measurement<UnitSpeed>(value: self, unit: .metersPerSecond).converted(to: .knots)
        let value = Int(ceil(converted.value))
        return Text("\(value)\(Text("kn").font(unitFont))")
    }
}
