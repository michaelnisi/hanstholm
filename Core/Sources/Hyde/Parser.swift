import Foundation

extension Data {
    func string() -> String? {
        String(data: self, encoding: .utf8)
    }

    func parsed() throws -> [String.SubSequence] {
        guard let string = string() else {
            throw Hyde.Fault.parsing
        }

        return try string
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
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        let attributed = try NSAttributedString(data: data, options: options, documentAttributes: nil)

        return attributed.string
    }

    func splitLines() -> [Self.SubSequence] {
        split(separator: "\n")
    }
}

extension Hyde.Station {
    var sectionHeadings: Set<Substring> {
        switch self {
        case .hanstholm:
            return ["Vindhastighed", "Vindretning", "Bølger", "Strøm"]
        case .hvideSande, .thorsminde:
            return ["Vindhastighed", "Vindretning", "Vandstand", "Bølger", "Slusedrift i dag"]
        }
    }
}

extension Array where Element == String.SubSequence {
    func maxWaveHeight(for station: Hyde.Station = .hanstholm) -> Substring? {
        substring(after: "max", within: "Bølger", sectionHeadings: station.sectionHeadings)
    }

    func middleWaveHeight(for station: Hyde.Station = .hanstholm) -> Substring? {
        substring(after: "middel", within: "Bølger", sectionHeadings: station.sectionHeadings)
    }

    func wavePeriod() -> Substring? {
        substring(after: "Bølgeperiode")
    }

    func waveDirection() -> Substring? {
        substring(after: "Bølgeretning")
    }

    func windCurrent(for station: Hyde.Station = .hanstholm) -> Substring? {
        substring(after: "aktuelt", within: "Vindhastighed", sectionHeadings: station.sectionHeadings)
    }

    func windMiddle(for station: Hyde.Station = .hanstholm) -> Substring? {
        substring(after: "middel", within: "Vindhastighed", sectionHeadings: station.sectionHeadings)
    }

    func windGust() -> Substring? {
        substring(after: "vindstød")
    }

    func windDirection(for station: Hyde.Station = .hanstholm) -> Substring? {
        substring(after: "middel", within: "Vindretning", sectionHeadings: station.sectionHeadings)
    }

    func substring(
        after label: Substring,
        within section: Substring? = nil,
        sectionHeadings: Set<Substring> = Hyde.Station.hanstholm.sectionHeadings
    ) -> Substring? {
        let startIndex: Int
        let endIndex: Int

        if let section {
            guard let sectionIndex = firstIndex(of: section) else { return nil }
            startIndex = sectionIndex + 1
            endIndex = self[startIndex...].firstIndex(where: { sectionHeadings.contains($0) }) ?? count
        } else {
            startIndex = 0
            endIndex = count
        }

        guard startIndex < endIndex,
              let labelIndex = self[startIndex..<endIndex].firstIndex(of: label),
              labelIndex + 1 < endIndex else {
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
        let numeric = prefix(while: { !$0.isWhitespace })
        guard let number = decimalFormatter.number(from: String(numeric)) else {
            return nil
        }
        return Double(truncating: number)
    }
}
