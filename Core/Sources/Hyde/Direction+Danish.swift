import DomainTypes

extension Direction {
    static let danishToCardinal: [String: Cardinal] = [
        "N": .north,
        "NNØ": .northNorthEast,
        "NØ": .northEast,
        "ØNØ": .eastNorthEast,
        "Ø": .east,
        "ØSØ": .eastSouthEast,
        "SØ": .southEast,
        "SSØ": .southSouthEast,
        "S": .south,
        "SSV": .southSouthWest,
        "SV": .southWest,
        "VSV": .westSouthWest,
        "V": .west,
        "VNV": .westNorthWest,
        "NV": .northWest,
        "NNV": .northNorthWest
    ]

    init?(danish string: String?) {
        guard let string, let cardinal = Direction.danishToCardinal[string] else {
            return nil
        }

        self.init(cardinal: cardinal)
    }
}
