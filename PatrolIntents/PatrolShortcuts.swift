import AppIntents

struct PatrolShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: HowIsTheSurfIntent(),
            phrases: [
                "\(.applicationName) surf",
                "\(.applicationName) \(\.$place)",
                "How is the surf in \(.applicationName)",
                "How is the surf at \(\.$place) in \(.applicationName)",
            ],
            shortTitle: "How Is The Surf",
            systemImageName: "water.waves"
        )

        AppShortcut(
            intent: SelectPlaceIntent(),
            phrases: [
                "Switch \(.applicationName) to \(\.$place)"
            ],
            shortTitle: "Select Surf Spot",
            systemImageName: "mappin.and.ellipse"
        )
    }
}
