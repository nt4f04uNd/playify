class Song {
  const Song({
    required this.songID,
    required this.albumID,
    required this.artistID,
    required this.albumArtistID,
    required this.genreID,
    required this.title,
    required this.artistName,
    required this.albumArtistName,
    required this.albumTitle,
    required this.trackNumber,
    required this.playCount,
    required this.discNumber,
    required this.genre,
    required this.releaseDate,
    required this.dateAdded,
    required this.duration,
    required this.isExplicit,
  });

  /// The persistent ID of the album containing this song.
  final String? albumID;

  /// The persistent ID of this song's artist.
  final String? artistID;

  /// The persistent ID of this song's album artist.
  final String? albumArtistID;

  /// The persistent ID of this song's genre.
  final String? genreID;

  ///The title of the album.
  final String albumTitle;

  ///The name of the song artist.
  final String artistName;

  /// The primary artist of the album containing this song.
  final String albumArtistName;

  ///The release date of the song.
  final DateTime? releaseDate;

  /// The date this song was added to the media library.
  final DateTime dateAdded;

  ///The genre of the song.
  final String genre;

  ///The title of the song.
  final String title;

  ///The Persistent Song ID of the song. Used to play or enqueue a song.
  final String songID;

  ///The track number of the song in an album.
  final int trackNumber;

  ///The amount of times the song has been played.
  final int playCount;

  ///The disc number the song belongs to in an album.
  final int discNumber;

  ///The total duration of the song.
  final double duration;

  ///Shows if the song is explicit.
  final bool isExplicit;

  static Song fromJson(Map<String, dynamic> map) => Song(
        albumTitle: map['albumTitle'] as String? ?? '',
        albumID: map['albumID']?.toString(),
        artistID: map['artistID']?.toString(),
        albumArtistID: map['albumArtistID']?.toString(),
        genreID: map['genreID']?.toString(),
        duration: (map['playbackDuration'] as num?)?.toDouble() ?? 0,
        title: map['songTitle'] as String? ?? '',
        trackNumber: (map['trackNumber'] as num?)?.toInt() ?? 0,
        discNumber: (map['discNumber'] as num?)?.toInt() ?? 0,
        isExplicit: map['isExplicitItem'] as bool? ?? false,
        genre: map['genre'] as String? ?? '',
        releaseDate: map['releaseDate'] is num
            ? DateTime.fromMillisecondsSinceEpoch((map['releaseDate'] as num).toInt())
            : null,
        dateAdded: DateTime.fromMillisecondsSinceEpoch(
          (map['dateAdded'] as num?)?.toInt() ?? 0,
        ),
        playCount: (map['playCount'] as num?)?.toInt() ?? 0,
        artistName: map['artist'] as String? ?? '',
        albumArtistName: map['albumArtist'] as String? ?? '',
        songID: _requiredID(map, 'songID'),
      );

  static String _requiredID(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      throw FormatException('Missing required song field: $key');
    }
    return value.toString();
  }

  @override
  String toString() {
    return 'Song Title: $title, Album Title: $albumTitle, Artist Name: $artistName, '
        'Duration: $duration, SongID: $songID\n';
  }
}
