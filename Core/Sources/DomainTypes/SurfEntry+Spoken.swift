extension SurfEntry.Wind {
    public var spoken: String {
        "wind is \(speed.current.knots(width: .wide)) from \(direction.spoken())"
    }
}

extension SurfEntry.Wave {
    public var spoken: String {
        "waves are \(middle.feet(width: .wide)) at \(period.seconds(width: .wide)) from \(direction.spoken())"
    }
}

extension SurfEntry {
    public var spokenSummary: String {
        "At \(place.name), \(wind.spoken), and \(wave.spoken)."
    }
}
