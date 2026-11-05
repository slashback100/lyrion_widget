import Foundation

enum LyrionConfig {
    static let defaultServer = "http://192.168.40.175:9000"
    static let defaultPlayerID = "88:a2:9e:a4:a0:e9"
    static let defaultPlayerName = "Salon"

    struct Player: Identifiable, Hashable {
        let id: String
        let name: String

        static let known: [Player] = [
            Player(id: "88:a2:9e:a4:a0:e9", name: "Salon"),
            Player(id: "b8:27:eb:65:7d:6b", name: "Terrasse bas"),
            Player(id: "b8:27:eb:17:f1:d0", name: "Chambre"),
            Player(id: "b8:27:eb:b5:94:08", name: "Terrasse haut / Billard"),
        ]

        static func name(for id: String) -> String {
            known.first(where: { $0.id == id })?.name ?? "Lecteur"
        }
    }
}
