import Foundation

enum KEXP {
    static let streamURL = URL(string: "https://kexp.streamguys1.com/kexp160.aac")!
    static let websiteURL = URL(string: "https://www.kexp.org/playlist/")!
}

/// Minimal client for the public KEXP v2 API.
struct KEXPClient: Sendable {
    private static let base = URL(string: "https://api.kexp.org/v2/")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func recentPlays(limit: Int = 12) async throws -> [KEXPPlay] {
        var comps = URLComponents(url: Self.base.appending(path: "plays/"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        let (data, _) = try await session.data(from: comps.url!)
        return try Self.decoder.decode(KEXPPlaysPage.self, from: data).results
    }

    func show(id: Int) async throws -> KEXPShow {
        let (data, _) = try await session.data(from: Self.base.appending(path: "shows/\(id)/"))
        return try Self.decoder.decode(KEXPShow.self, from: data)
    }

    /// Fetches the latest plays plus the show, and optionally artwork for the
    /// current track and the first `recentArtworkCount` recent tracks.
    func nowPlaying(recentCount: Int = 3, includeArtwork: Bool, recentArtworkCount: Int = 0) async throws -> NowPlaying {
        let plays = try await recentPlays()
        guard let latest = plays.first else {
            return NowPlaying(current: nil, showName: nil, recent: [], fetchedAt: .now)
        }

        let tracks = plays.filter(\.isTrack).compactMap(Self.trackInfo)
        // During an air break the latest play is not a track.
        var current = latest.isTrack ? tracks.first : nil
        var recent = Array(tracks.drop(while: { $0.id == current?.id }).prefix(recentCount))

        async let showName: String? = {
            guard let id = latest.show else { return nil }
            return try? await show(id: id).displayName
        }()

        if includeArtwork {
            let currentURL = current?.artworkURL
            async let currentArt = artwork(at: currentURL)
            var recentArt: [Data?] = []
            for track in recent.prefix(recentArtworkCount) {
                recentArt.append(await artwork(at: track.artworkURL))
            }
            current?.artwork = await currentArt
            for (i, data) in recentArt.enumerated() { recent[i].artwork = data }
        }

        return NowPlaying(current: current, showName: await showName, recent: recent, fetchedAt: .now)
    }

    private func artwork(at url: URL?) async -> Data? {
        guard let url else { return nil }
        return try? await session.data(from: url).0
    }

    private static func trackInfo(_ play: KEXPPlay) -> TrackInfo? {
        guard let title = play.song, !title.isEmpty else { return nil }
        return TrackInfo(
            id: play.id,
            title: title,
            artist: play.artist ?? "Unknown artist",
            album: play.album,
            airdate: play.airdate,
            artworkURL: play.thumbnailURL,
            artwork: nil
        )
    }
}
