import Foundation
import SwiftUI

extension Double {
    public func feetText() -> Text {
        let converted = Measurement<UnitLength>(value: self, unit: .meters).converted(to: .feet)
        let value = Int(ceil(converted.value))
        return Text("\(value)\(Text("ft").font(.caption))")
    }

    public func knotsText() -> Text {
        let converted = Measurement<UnitSpeed>(value: self, unit: .metersPerSecond).converted(
            to: .knots)
        let value = Int(ceil(converted.value))
        return Text("\(value)\(Text("kn").font(.caption))")
    }
}
