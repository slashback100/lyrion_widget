import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("server") private var server = LyrionConfig.defaultServer
    @AppStorage("playerID") private var playerID = LyrionConfig.defaultPlayerID

    @State private var status: LyrionStatus?
    @State private var artwork: Data?
    @State private var errorMessage: String?

    private var client: LyrionClient {
        LyrionClient(server: server, playerID: playerID)
    }

    private var title: String {
        guard let value = status?.title, !value.isEmpty else { return "Rien en lecture" }
        return value
    }

    private var subtitle: String {
        guard let value = status?.artist, !value.isEmpty else {
            return LyrionConfig.Player.name(for: playerID)
        }
        return value
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    nowPlaying
                    controls
                    Divider()
                    settings
                    Text("Le widget se configure séparément : appui long sur le widget, puis « Modifier le widget ».")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Lyrion")
            .task(id: "\(server)|\(playerID)") {
                await poll()
            }
            .refreshable {
                await refresh()
            }
        }
    }

    private var nowPlaying: some View {
        VStack(spacing: 12) {
            Group {
                if let artwork, let image = UIImage(data: artwork) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "music.note")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(radius: 12, y: 6)

            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 22) {
            controlButton("backward.fill", command: "previous")
            controlButton(
                status?.isPlaying == true ? "pause.fill" : "play.fill",
                command: status?.isPlaying == true ? "pause" : "play",
                large: true
            )
            controlButton("forward.fill", command: "next")
            controlButton(
                status?.isMuted == true ? "speaker.slash.fill" : "speaker.wave.2.fill",
                command: "mute"
            )
        }
    }

    private func controlButton(_ symbol: String, command: String, large: Bool = false) -> some View {
        Button {
            Task { await perform(command) }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: large ? 30 : 22, weight: .semibold))
                .frame(width: large ? 66 : 52, height: large ? 66 : 52)
                .background(Circle().fill(Color.accentColor.opacity(large ? 0.95 : 0.15)))
                .foregroundStyle(large ? Color.white : Color.accentColor)
        }
        .buttonStyle(.plain)
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Réglages de l'app")
                .font(.headline)

            TextField("Serveur", text: $server)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .textFieldStyle(.roundedBorder)

            Picker("Lecteur", selection: $playerID) {
                ForEach(LyrionConfig.Player.known) { player in
                    Text(player.name).tag(player.id)
                }
            }
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @MainActor
    private func perform(_ command: String) async {
        do {
            try await client.perform(command)
            try? await Task.sleep(nanoseconds: 350_000_000)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func refresh() async {
        do {
            let newStatus = try await client.status()
            status = newStatus
            artwork = await client.artworkData(for: newStatus)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func poll() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(nanoseconds: 5_000_000_000)
        }
    }
}
