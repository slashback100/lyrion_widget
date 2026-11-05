import SwiftUI
import UIKit
import WidgetKit

struct LyrionEntry: TimelineEntry {
    let date: Date
    let status: LyrionStatus?
    let artwork: Data?
    let server: String
    let playerID: String
    let playerName: String
}

struct LyrionProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LyrionEntry {
        LyrionEntry(
            date: Date(),
            status: LyrionStatus(
                title: "Billie Jean",
                artist: "Michael Jackson",
                album: "Thriller 40",
                isPlaying: true,
                isPaused: false,
                isMuted: false,
                volume: 30,
                artworkURL: nil
            ),
            artwork: nil,
            server: LyrionConfig.defaultServer,
            playerID: LyrionConfig.defaultPlayerID,
            playerName: LyrionConfig.defaultPlayerName
        )
    }

    func snapshot(for configuration: LyrionWidgetConfiguration, in context: Context) async -> LyrionEntry {
        await entry(for: configuration)
    }

    func timeline(for configuration: LyrionWidgetConfiguration, in context: Context) async -> Timeline<LyrionEntry> {
        let entry = await entry(for: configuration)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
    }

    private func entry(for configuration: LyrionWidgetConfiguration) async -> LyrionEntry {
        let server: String
        if let value = configuration.server, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            server = value
        } else {
            server = LyrionConfig.defaultServer
        }

        let playerID = configuration.player?.id ?? LyrionConfig.defaultPlayerID
        let playerName = configuration.player?.name ?? LyrionConfig.Player.name(for: playerID)
        let client = LyrionClient(server: server, playerID: playerID)

        let status = try? await client.status()
        var artwork: Data?
        if let status {
            artwork = await client.artworkData(for: status)
        }

        return LyrionEntry(
            date: Date(),
            status: status,
            artwork: artwork,
            server: server,
            playerID: playerID,
            playerName: playerName
        )
    }
}

struct LyrionWidgetView: View {
    let entry: LyrionEntry

    @Environment(\.widgetFamily) private var family

    private var isLarge: Bool { family == .systemLarge }

    private var title: String {
        guard let value = entry.status?.title, !value.isEmpty else { return "Lyrion" }
        return value
    }

    private var subtitle: String {
        guard let value = entry.status?.artist, !value.isEmpty else { return entry.playerName }
        return value
    }

    private var statusColor: Color {
        if entry.status?.isPlaying == true { return .green }
        if entry.status?.isPaused == true { return .orange }
        return .gray
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isLarge ? 14 : 9) {
            header
            Spacer(minLength: 0)
            controls
        }
        .padding(isLarge ? 18 : 14)
        .containerBackground(for: .widget) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.07, blue: 0.13),
                        Color(red: 0.11, green: 0.16, blue: 0.28),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let data = entry.artwork, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 32)
                        .opacity(0.35)
                        .clipped()
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: isLarge ? 14 : 11) {
            artworkView

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)

                if isLarge {
                    Text(entry.status?.album ?? "")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .padding(.top, 2)
        }
    }

    private var artworkView: some View {
        Group {
            if let data = entry.artwork, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: isLarge ? 30 : 22, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: isLarge ? 96 : 64, height: isLarge ? 96 : 64)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var controls: some View {
        HStack(spacing: isLarge ? 8 : 5) {
            controlButton("backward.fill", command: "previous")
            controlButton("play.fill", command: "play")
            controlButton("pause.fill", command: "pause")
            controlButton("forward.fill", command: "next")
            controlButton(
                entry.status?.isMuted == true ? "speaker.slash.fill" : "speaker.wave.2.fill",
                command: "mute"
            )
        }
    }

    private func controlButton(_ symbol: String, command: String) -> some View {
        Button(intent: LyrionControlIntent(server: entry.server, playerID: entry.playerID, command: command)) {
            Image(systemName: symbol)
                .font(.system(size: isLarge ? 20 : 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: isLarge ? 44 : 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct LyrionWidget: Widget {
    let kind: String = "LyrionWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: LyrionWidgetConfiguration.self,
            provider: LyrionProvider()
        ) { entry in
            LyrionWidgetView(entry: entry)
        }
        .configurationDisplayName("Télécommande Lyrion")
        .description("Play, pause, piste précédente/suivante et mute, avec la pochette en cours.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
