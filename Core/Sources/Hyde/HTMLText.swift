import Foundation

struct HTMLTextExtractor {
    private static let blockTags: Set<String> = [
        "address", "article", "aside", "blockquote", "body", "br", "dd", "div", "dl", "dt",
        "fieldset", "figcaption", "figure", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6",
        "header", "hr", "li", "main", "nav", "ol", "p", "pre", "section", "table", "tbody", "td",
        "tfoot", "th", "thead", "tr", "ul",
    ]

    private static let rawTextTags: Set<String> = ["script", "style", "title"]

    private static let namedEntities: [String: String] = [
        "amp": "&",
        "lt": "<",
        "gt": ">",
        "quot": "\"",
        "apos": "'",
        "nbsp": "\u{00A0}",
    ]

    private static let longestEntityLength = 10

    private var remaining: Substring

    private var text = ""

    init(html: String) {
        remaining = html[...]
    }

    static func text(from html: String) -> String {
        var extractor = HTMLTextExtractor(html: html)

        return extractor.extract()
    }

    private mutating func extract() -> String {
        while let character = remaining.first {
            switch character {
            case "<":
                consumeMarkup()
            case "&":
                consumeEntity()
            default:
                appendCollapsingWhitespace(character)
                remaining.removeFirst()
            }
        }

        return text
    }

    private mutating func consumeMarkup() {
        let afterBracket = remaining.dropFirst()

        if afterBracket.hasPrefix("!--") {
            skipPast("-->")

            return
        }

        if afterBracket.first == "!" || afterBracket.first == "?" {
            skipPast(">")

            return
        }

        let isClosing = afterBracket.first == "/"
        let name = afterBracket.dropFirst(isClosing ? 1 : 0)
            .prefix(while: { $0.isLetter || $0.isNumber })
            .lowercased()

        guard !name.isEmpty else {
            appendLiteral("<")
            remaining.removeFirst()

            return
        }

        skipPastTagEnd()

        if !isClosing && Self.rawTextTags.contains(name) {
            skipPast("</\(name)")
            skipPast(">")
        }

        if Self.blockTags.contains(name) {
            endLine()
        }
    }

    private mutating func consumeEntity() {
        let candidate = remaining.dropFirst().prefix(Self.longestEntityLength + 1)

        guard
            let semicolon = candidate.firstIndex(of: ";"),
            let decoded = Self.decode(entity: candidate[..<semicolon])
        else {
            appendLiteral("&")
            remaining.removeFirst()

            return
        }

        appendLiteral(decoded)
        remaining = remaining[remaining.index(after: semicolon)...]
    }

    private static func decode(entity: Substring) -> String? {
        guard entity.hasPrefix("#") else {
            return namedEntities[String(entity)]
        }

        let digits = entity.dropFirst()
        let isHexadecimal = digits.hasPrefix("x") || digits.hasPrefix("X")
        let codePoint =
            isHexadecimal
            ? UInt32(digits.dropFirst(), radix: 16)
            : UInt32(digits, radix: 10)

        return codePoint.flatMap(Unicode.Scalar.init).map { String(Character($0)) }
    }

    private mutating func skipPast(_ marker: String) {
        guard let range = remaining.range(of: marker, options: .caseInsensitive) else {
            remaining = ""

            return
        }

        remaining = remaining[range.upperBound...]
    }

    private mutating func skipPastTagEnd() {
        var openQuote: Character?

        while let character = remaining.popFirst() {
            if let quote = openQuote {
                openQuote = character == quote ? nil : quote
            } else if character == "\"" || character == "'" {
                openQuote = character
            } else if character == ">" {
                return
            }
        }
    }

    private var isAtLineStart: Bool {
        text.isEmpty || text.hasSuffix("\n")
    }

    private mutating func appendCollapsingWhitespace(_ character: Character) {
        guard character.isWhitespace else {
            text.append(character)

            return
        }

        guard !isAtLineStart && !text.hasSuffix(" ") else {
            return
        }

        text.append(" ")
    }

    private mutating func appendLiteral(_ string: String) {
        text.append(string)
    }

    private mutating func endLine() {
        if text.hasSuffix(" ") {
            text.removeLast()
        }

        guard !isAtLineStart else {
            return
        }

        text.append("\n")
    }
}
