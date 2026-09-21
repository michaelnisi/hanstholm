import SwiftUI

public struct ContrastColor: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public var color: Color { Color(red: red, green: green, blue: blue) }
}

public enum WCAGContrast {
    public static func relativeLuminance(of color: ContrastColor) -> Double {
        func linearize(_ component: Double) -> Double {
            component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(color.red)
            + 0.7152 * linearize(color.green)
            + 0.0722 * linearize(color.blue)
    }

    public static func ratio(_ a: ContrastColor, _ b: ContrastColor) -> Double {
        let lumA = relativeLuminance(of: a)
        let lumB = relativeLuminance(of: b)
        let lighter = max(lumA, lumB)
        let darker = min(lumA, lumB)
        return (lighter + 0.05) / (darker + 0.05)
    }
}
