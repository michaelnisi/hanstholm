import AppIntents

struct PatrolShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: HowIsTheSurfIntent(),
            phrases: [
                "\(.applicationName) surf",
                "\(.applicationName) waves",
                "\(.applicationName) wind",
                "\(.applicationName) conditions",
                "How is the surf in \(.applicationName)",
                "What's the surf like in \(.applicationName)"
            ],
            shortTitle: "How Is The Surf",
            systemImageName: "water.waves"
        )
    }
}
