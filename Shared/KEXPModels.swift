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
    let releaseGroupID: String?

    enum CodingKeys: String, CodingKey {
        case id, airdate, show, song, artist, album
        case playType = "play_type"
        case thumbnailURI = "thumbnail_uri"
        case releaseGroupID = "release_group_id"
    }

    var isTrack: Bool { playType == "trackplay" }

    /// KEXP's own thumbnail, or else the album's front cover from the Cover Art Archive
    /// (KEXP leaves `thumbnail_uri` empty for many plays that still have a release group).
    var thumbnailURL: URL? {
        if let thumbnailURI, !thumbnailURI.isEmpty { return URL(string: thumbnailURI) }
        guard let releaseGroupID, !releaseGroupID.isEmpty else { return nil }
        return URL(string: "https://coverartarchive.org/release-group/\(releaseGroupID)/front-250")
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
    /// The current show's ID, used to link to its page on kexp.org.
    var showID: Int? = nil
    var recent: [TrackInfo]
    var fetchedAt: Date
    /// True when this is a stand-in because the last fetch failed.
    var offline = false

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
