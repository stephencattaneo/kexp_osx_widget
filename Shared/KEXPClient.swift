import Foundation

enum KEXP {
    static let streamURL = URL(string: "https://kexp.streamguys1.com/kexp160.aac")!
    static let websiteURL = URL(string: "https://www.kexp.org/playlist/")!
    static let homeURL = URL(string: "https://www.kexp.org")!

    /// A show episode's page (its playlist) on kexp.org.
    static func showURL(id: Int) -> URL {
        URL(string: "https://www.kexp.org/playlist/show/\(id)/")!
    }
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

    /// kexp.org's own player uses this when it can't determine the listener's location.
    static let defaultPlaylistLocation = 3

    /// The playlist location for this listener's IP (e.g. 2 = Bay Area/KEXC, 3 = Seattle/default),
    /// as kexp.org's player determines it. Local shows differ by location. Cached for an hour.
    func playlistLocation() async -> Int {
        if let cached = await PlaylistLocationCache.shared.value { return cached }
        struct Response: Decodable { let location: Int }
        let url = URL(string: "https://www.kexp.org/location_livestream/")!
        guard let (data, _) = try? await session.data(from: url),
              let location = try? JSONDecoder().decode(Response.self, from: data).location else {
            return Self.defaultPlaylistLocation   // don't cache failures
        }
        await PlaylistLocationCache.shared.store(location)
        return location
    }

    func recentPlays(limit: Int = 12, location: Int) async throws -> [KEXPPlay] {
        var comps = URLComponents(url: Self.base.appending(path: "plays/"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "playlist_location", value: String(location)),
        ]
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
        let plays = try await recentPlays(location: await playlistLocation())
        guard let latest = plays.first else {
            return NowPlaying(current: nil, showName: nil, recent: [], fetchedAt: .now)
        }

        let tracks = plays.filter(\.isTrack).compactMap(Self.trackInfo)
        // During an air break the latest play is not a track.
        var current = latest.isTrack ? tracks.first : nil
        var recent = Array(tracks.drop(while: { $0.id == current?.id }).prefix(recentCount))

        async let showName: String? = {
            guard let id = latest.show else { return nil }
            // A show's name doesn't change during the show; look it up once per show.
            return await Self.showNames.value(for: id) { try? await show(id: id).displayName }
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

        return NowPlaying(current: current, showName: await showName, showID: latest.show, recent: recent, fetchedAt: .now)
    }

    /// Album art is served without cache headers, so keep it here instead of
    /// re-downloading the same covers on every refresh.
    private static let artworkCache = ValueCache<URL, Data>(limit: 40)
    private static let showNames = ValueCache<Int, String>(limit: 8)

    private func artwork(at url: URL?) async -> Data? {
        guard let url else { return nil }
        return await Self.artworkCache.value(for: url) {
            guard let (data, response) = try? await session.data(from: url),
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  http.mimeType?.hasPrefix("image/") == true else { return nil }   // e.g. Cover Art Archive 404s
            return data
        }
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

/// Remembers the IP-derived playlist location for an hour (it only changes if the Mac moves).
actor PlaylistLocationCache {
    static let shared = PlaylistLocationCache()
    private var location: Int?
    private var storedAt: Date?

    var value: Int? {
        guard let location, let storedAt, Date.now.timeIntervalSince(storedAt) < 3600 else { return nil }
        return location
    }

    func store(_ location: Int) {
        self.location = location
        storedAt = .now
    }
}
