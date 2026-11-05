import Foundation

struct LyrionStatus: Equatable {
    var title: String
    var artist: String
    var album: String
    var isPlaying: Bool
    var isPaused: Bool
    var isMuted: Bool
    var volume: Int
    var artworkURL: URL?

    static let empty = LyrionStatus(
        title: "",
        artist: "",
        album: "",
        isPlaying: false,
        isPaused: false,
        isMuted: false,
        volume: 0,
        artworkURL: nil
    )
}

enum LyrionError: LocalizedError {
    case invalidServer
    case badResponse(Int)
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidServer:
            return "Adresse du serveur invalide."
        case .badResponse(let code):
            return "Le serveur a répondu \(code)."
        case .invalidPayload:
            return "Réponse du serveur illisible."
        }
    }
}

struct LyrionClient {
    let server: String
    let playerID: String

    init(server: String = LyrionConfig.defaultServer, playerID: String = LyrionConfig.defaultPlayerID) {
        self.server = server
        self.playerID = playerID
    }

    private var baseURL: URL? {
        var value = server.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if !value.contains("://") {
            value = "http://" + value
        }
        while value.hasSuffix("/") {
            value.removeLast()
        }
        return URL(string: value)
    }

    private var rpcURL: URL? {
        baseURL?.appendingPathComponent("jsonrpc.js")
    }

    func send(_ command: [Any]) async throws {
        guard let url = rpcURL else { throw LyrionError.invalidServer }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 12

        let payload: [String: Any] = [
            "id": 1,
            "method": "slim.request",
            "params": [playerID, command],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LyrionError.invalidPayload
        }
        guard (200..<300).contains(http.statusCode) else {
            throw LyrionError.badResponse(http.statusCode)
        }
    }

    func perform(_ command: String) async throws {
        switch command {
        case "play":
            try await send(["play"])
        case "pause":
            try await send(["pause", 1])
        case "next":
            try await send(["button", "jump_fwd"])
        case "previous":
            try await send(["button", "jump_rew"])
        case "mute":
            try await send(["mixer", "muting", "toggle"])
        default:
            break
        }
    }

    func status() async throws -> LyrionStatus {
        guard let url = rpcURL else { throw LyrionError.invalidServer }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 12

        let payload: [String: Any] = [
            "id": 1,
            "method": "slim.request",
            "params": [playerID, ["status", "-", "1", "tags:uBJjKlaxc"]],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LyrionError.invalidPayload
        }
        guard (200..<300).contains(http.statusCode) else {
            throw LyrionError.badResponse(http.statusCode)
        }
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = root["result"] as? [String: Any]
        else {
            throw LyrionError.invalidPayload
        }

        let mode = (result["mode"] as? String) ?? "stop"
        let volume = intValue(result["mixer volume"]) ?? 0
        let isMuted = (intValue(result["mixer muting"]) ?? 0) != 0

        var title = ""
        var artist = ""
        var album = ""
        var artworkURL: URL?

        if let loop = result["playlist_loop"] as? [[String: Any]], let current = loop.first {
            title = (current["title"] as? String) ?? ""
            artist = (current["artist"] as? String) ?? ""
            album = (current["album"] as? String) ?? ""

            if let raw = current["artwork_url"] as? String, !raw.isEmpty {
                artworkURL = makeArtworkURL(from: raw)
            }
            if artworkURL == nil,
               let cover = current["coverid"] as? String,
               !cover.isEmpty,
               cover != "0" {
                artworkURL = makeArtworkURL(from: "/music/\(cover)/cover.jpg")
            }
        }

        if title.isEmpty, let currentTitle = result["current_title"] as? String {
            title = currentTitle
        }

        return LyrionStatus(
            title: title,
            artist: artist,
            album: album,
            isPlaying: mode == "play",
            isPaused: mode == "pause",
            isMuted: isMuted,
            volume: volume,
            artworkURL: artworkURL
        )
    }

    func artworkData(for status: LyrionStatus) async -> Data? {
        guard let url = status.artworkURL else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }

    private func makeArtworkURL(from raw: String) -> URL? {
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
            return URL(string: raw)
        }
        guard let base = baseURL else { return nil }
        if raw.hasPrefix("/") {
            return URL(string: base.absoluteString + raw)
        }
        return URL(string: base.absoluteString + "/" + raw)
    }

    private func intValue(_ value: Any?) -> Int? {
        if let int = value as? Int {
            return int
        }
        if let string = value as? String {
            return Int(string)
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        return nil
    }
}
