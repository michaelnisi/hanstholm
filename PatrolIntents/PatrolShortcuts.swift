import AppIntents

struct PatrolShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: HowIsTheSurfIntent(),
            phrases: [
                "How is the surf in \(.applicationName)",
                "Ask \(.applicationName) how is the surf",
                "What's the surf like in \(.applicationName)"
            ],
            shortTitle: "How Is The Surf",
            systemImageName: "water.waves"
        )
    }
}
