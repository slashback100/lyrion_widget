import AppIntents
import WidgetKit

struct LyrionControlIntent: AppIntent {
    static var title: LocalizedStringResource = "Commande Lyrion"
    static var description = IntentDescription("Envoie play, pause, piste suivante, piste précédente ou mute au lecteur Lyrion.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Serveur")
    var server: String?

    @Parameter(title: "Lecteur")
    var playerID: String?

    @Parameter(title: "Commande")
    var command: String?

    init() {}

    init(server: String, playerID: String, command: String) {
        self.server = server
        self.playerID = playerID
        self.command = command
    }

    func perform() async throws -> some IntentResult {
        let client = LyrionClient(
            server: server ?? LyrionConfig.defaultServer,
            playerID: playerID ?? LyrionConfig.defaultPlayerID
        )
        try await client.perform(command ?? "play")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct LyrionPlayerEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Lecteur Lyrion"
    static var defaultQuery = LyrionPlayerQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
    }
}

struct LyrionPlayerQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [LyrionPlayerEntity] {
        LyrionConfig.Player.known
            .filter { identifiers.contains($0.id) }
            .map { LyrionPlayerEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [LyrionPlayerEntity] {
        LyrionConfig.Player.known.map { LyrionPlayerEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> LyrionPlayerEntity? {
        guard let player = LyrionConfig.Player.known.first(where: { $0.id == LyrionConfig.defaultPlayerID }) else {
            return nil
        }
        return LyrionPlayerEntity(id: player.id, name: player.name)
    }
}

struct LyrionWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Télécommande Lyrion"
    static var description = IntentDescription("Choisis le serveur Lyrion et le lecteur à contrôler.")

    @Parameter(title: "Serveur")
    var server: String?

    @Parameter(title: "Lecteur")
    var player: LyrionPlayerEntity?

    init() {}
}
