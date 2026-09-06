extension SurfEntry {
    public var spokenSummary: String {
        let windPhrase = "wind is \(wind.speed.current.knots(width: .wide)) from \(wind.direction.spoken())"
        let wavePhrase = "waves are \(wave.middle.feet(width: .wide)) at \(wave.period.seconds(width: .wide)) from \(wave.direction.spoken())"

        return "At \(place.name), \(windPhrase), and \(wavePhrase)."
    }
}
