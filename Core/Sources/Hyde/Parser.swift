import Foundation

extension Data {
    func string() -> String? {
        String(data: self, encoding: .utf8)
    }

    func parsed() throws -> [String.SubSequence] {
        guard let string = string() else {
            throw Hyde.Fault.parsing
        }

        return
            try string
            .stripOutHtml()
            .splitLines()
    }
}

extension String {
    func stripOutHtml() throws -> String {
        guard let data = self.data(using: .unicode) else {
            throw Hyde.Fault.parsing
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        let attributed = try NSAttributedString(
            data: data, options: options, documentAttributes: nil)

        return attributed.string
    }

    func splitLines() -> [Self.SubSequence] {
        split(separator: "\n")
    }
}

extension Hyde {
    enum Label {
        static let maxWaveHeight: Substring = "Max Bølgehøjde"
        static let middleWaveHeight: Substring = "Middel Bølgehøjde"
        static let wavePeriod: Substring = "Bølgeperiode"
        static let waveDirection: Substring = "Bølgeretning"
        static let windCurrent: Substring = "Aktuel vindhastighed"
        static let windMiddle: Substring = "Middel vindhastighed"
        static let windGust: Substring = "Vindstød"
        static let windDirection: Substring = "Vindretning middel"
    }
}

extension Array where Element == String.SubSequence {
    func maxWaveHeight() -> Substring? {
        substring(after: Hyde.Label.maxWaveHeight)
    }

    func middleWaveHeight() -> Substring? {
        substring(after: Hyde.Label.middleWaveHeight)
    }

    func wavePeriod() -> Substring? {
        substring(after: Hyde.Label.wavePeriod)
    }

    func waveDirection() -> Substring? {
        substring(after: Hyde.Label.waveDirection)?.withoutDegreeSign()
    }

    func windCurrent() -> Substring? {
        substring(after: Hyde.Label.windCurrent)
    }

    func windMiddle() -> Substring? {
        substring(after: Hyde.Label.windMiddle)
    }

    func windGust() -> Substring? {
        substring(after: Hyde.Label.windGust)
    }

    func windDirection() -> Substring? {
        substring(after: Hyde.Label.windDirection)?.withoutDegreeSign()
    }

    func substring(after label: Substring) -> Substring? {
        guard let labelIndex = firstIndex(of: label), labelIndex + 1 < count else {
            return nil
        }

        return self[labelIndex + 1]
    }

    func required(_ label: Substring) throws -> Substring {
        guard let value = substring(after: label) else {
            throw Hyde.Fault.missing(String(label))
        }

        return value
    }
}

private let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: Locale.LanguageCode.danish.identifier)
    return formatter
}()

extension Substring {
    func double() -> Double? {
        let numeric = prefix(while: { $0.isNumber || $0 == "," || $0 == "-" })
        guard let number = decimalFormatter.number(from: String(numeric)) else {
            return nil
        }
        return Double(truncating: number)
    }

    var containsDigit: Bool {
        contains { $0.isASCII && $0.isNumber }
    }

    func withoutDegreeSign() -> Substring {
        prefix(while: { $0 != "°" })
    }
}
