import Foundation
import SwiftUI

extension Double {
    public enum Element {
        case wind, wave
    }

    public func text(element: Element) -> Text {
        switch element {
        case .wave:
            feetText()
        case .wind:
            knotsText()
        }
    }

    public func feetText(unitFont: Font = .caption) -> Text {
        let converted = Measurement<UnitLength>(value: self, unit: .meters).converted(to: .feet)
        let value = Int(ceil(converted.value))
        return Text("\(value)\(Text("ft").font(unitFont))")
    }

    public func knotsText(unitFont: Font = .caption) -> Text {
        let converted = Measurement<UnitSpeed>(value: self, unit: .metersPerSecond).converted(
            to: .knots)
        let value = Int(ceil(converted.value))
        return Text("\(value)\(Text("kn").font(unitFont))")
    }
}

extension Optional where Wrapped == Double {
    public func knotsText(unitFont: Font = .caption) -> Text {
        self?.knotsText(unitFont: unitFont) ?? Text("–")
    }
}
