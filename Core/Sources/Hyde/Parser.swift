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

extension Array where Element == String.SubSequence {
    func maxWaveHeight() -> Substring? {
        substring(after: "Max Bølgehøjde")
    }

    func middleWaveHeight() -> Substring? {
        substring(after: "Middel Bølgehøjde")
    }

    func wavePeriod() -> Substring? {
        substring(after: "Bølgeperiode")
    }

    func waveDirection() -> Substring? {
        substring(after: "Bølgeretning")?.withoutDegreeSign()
    }

    func windCurrent() -> Substring? {
        substring(after: "Aktuel vindhastighed")
    }

    func windMiddle() -> Substring? {
        substring(after: "Middel vindhastighed")
    }

    func windGust() -> Substring? {
        substring(after: "Vindstød")
    }

    func windDirection() -> Substring? {
        substring(after: "Vindretning middel")?.withoutDegreeSign()
    }

    func substring(after label: Substring) -> Substring? {
        guard let labelIndex = firstIndex(of: label), labelIndex + 1 < count else {
            return nil
        }

        return self[labelIndex + 1]
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

    func withoutDegreeSign() -> Substring {
        prefix(while: { $0 != "°" })
    }
}
