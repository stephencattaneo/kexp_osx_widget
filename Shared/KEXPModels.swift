import Foundation

/// A single entry from `https://api.kexp.org/v2/plays/`.
struct KEXPPlay: Codable, Hashable, Sendable {
    let id: Int
    let airdate: Date
    let show: Int?
    let playType: String
    let song: String?
    let artist: String?
    let album: String?
    let thumbnailURI: String?

    enum CodingKeys: String, CodingKey {
        case id, airdate, show, song, artist, album
        case playType = "play_type"
        case thumbnailURI = "thumbnail_uri"
    }

    var isTrack: Bool { playType == "trackplay" }

    var thumbnailURL: URL? {
        guard let thumbnailURI, !thumbnailURI.isEmpty else { return nil }
        return URL(string: thumbnailURI)
    }
}

struct KEXPPlaysPage: Codable, Sendable {
    let results: [KEXPPlay]
}

/// `https://api.kexp.org/v2/shows/{id}/`
struct KEXPShow: Codable, Hashable, Sendable {
    let id: Int
    let programName: String?
    let hostNames: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case programName = "program_name"
        case hostNames = "host_names"
    }

    /// e.g. "The Midday Show with Cheryl Waters"
    var displayName: String? {
        let hosts = (hostNames ?? []).filter { !$0.isEmpty }
        switch (programName, hosts.isEmpty) {
        case let (name?, false): return "\(name) with \(ListFormatter.localizedString(byJoining: hosts))"
        case let (name?, true): return name
        case (nil, false): return ListFormatter.localizedString(byJoining: hosts)
        case (nil, true): return nil
        }
    }
}

/// A track as displayed in the UI, with optional pre-fetched artwork bytes
/// (widgets can't load remote images at render time).
struct TrackInfo: Hashable, Sendable {
    let id: Int
    let title: String
    let artist: String
    let album: String?
    let airdate: Date
    let artworkURL: URL?
    var artwork: Data?
}

/// Everything the widget and menu-bar UI need to render.
struct NowPlaying: Hashable, Sendable {
    /// `nil` while KEXP is in an air break.
    var current: TrackInfo?
    var showName: String?
    var recent: [TrackInfo]
    var fetchedAt: Date

    static let placeholder = NowPlaying(
        current: TrackInfo(id: 0, title: "Song title", artist: "Artist", album: "Album",
                           airdate: .now, artworkURL: nil, artwork: nil),
        showName: "KEXP 90.3 FM",
        recent: (1...3).map {
            TrackInfo(id: $0, title: "Song title", artist: "Artist", album: nil,
                      airdate: .now.addingTimeInterval(Double(-$0) * 240), artworkURL: nil, artwork: nil)
        },
        fetchedAt: .now
    )
}
