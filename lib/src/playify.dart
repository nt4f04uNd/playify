import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:playify/src/class/album/album.dart';
import 'package:playify/src/class/artist/artist.dart';
import 'package:playify/src/class/playlist/playlist.dart';
import 'package:playify/src/class/song/song.dart';
import 'package:playify/src/class/song_information/song_information.dart';

import '../playify.dart';
import 'class/repeat/repeat.dart';
import 'class/shuffle/shuffle.dart';

enum PlayifyStatus {
  stopped,
  playing,
  paused,
  interrupted,
  seekingForward,
  seekingBackward,
  unknown,
}

class Playify {
  factory Playify() => instance;

  Playify._();

  static final Playify instance = Playify._();

  static const MethodChannel playerChannel = MethodChannel(
    'com.kaya.playify/playify',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.kaya.playify/playify_status',
  );

  late final Stream<PlayifyStatus> statusStream =
      _eventChannel.receiveBroadcastStream().cast<int>().map(_intToStatus);

  /// Fetches all songs as a flat list without loading artwork.
  Future<List<Song>> getSongs() async {
    final result = await playerChannel.invokeListMethod<Map>('getSongs');
    return result
            ?.map((song) => Song.fromJson(Map<String, dynamic>.from(song)))
            .toList(growable: false) ??
        const [];
  }

  /// Loads artwork for the song identified by [songID].
  Future<Uint8List?> getArtwork({
    required String songID,
    required int width,
    required int height,
  }) {
    return playerChannel.invokeMethod<Uint8List>('getArtwork', {
      'songID': songID,
      'width': width,
      'height': height,
    });
  }

  ///Set the queue by giving the [songIDs] desired to be added to the queue.
  ///If [startPlaying] is false, the queue will not autoplay.
  ///If [startID] is provided, the queue will start from the song with
  ///the id [startID].
  Future<void> setQueue({
    required List<String> songIDs,
    required String startID,
    bool startPlaying = true,
  }) async {
    if (!songIDs.contains(startID)) {
      throw PlatformException(
        code: 'Incorrect Arguments!',
        message: 'songIDs must contain startID if provided.',
      );
    }
    await playerChannel.invokeMethod('setQueue', <String, dynamic>{
      'songIDs': songIDs,
      'startPlaying': startPlaying,
      'startID': startID,
    });
  }

  ///Play the most recent queue.
  Future<void> play() async {
    await playerChannel.invokeMethod('play');
  }

  ///Play a single song by giving its [songID].
  Future<void> playItem({required String songID}) =>
      setQueue(songIDs: [songID], startID: songID);

  ///Pause playing.
  Future<void> pause() async {
    await playerChannel.invokeMethod('pause');
  }

  ///Skip to the next song in the queue.
  Future<void> next() async {
    await playerChannel.invokeMethod('next');
  }

  ///Check if there is a song currently playing.
  Future<bool> isPlaying() async {
    final isPlaying = await playerChannel.invokeMethod('isPlaying') ?? false;
    return isPlaying;
  }

  ///Skip to the previous song in the queue.
  Future<void> previous() async {
    await playerChannel.invokeMethod('previous');
  }

  ///Seek forward in the song currently playing in the queue.
  ///Must call `endSeeking()` or will not stop seeking.
  Future<void> seekForward() async {
    await playerChannel.invokeMethod('seekForward');
  }

  ///Seek backward in the song currently playing in the queue.
  ///Must call `endSeeking()` or will not stop seeking.
  Future<void> seekBackward() async {
    await playerChannel.invokeMethod('seekBackward');
  }

  ///Stop seeking.
  Future<void> endSeeking() async {
    await playerChannel.invokeMethod('endSeeking');
  }

  ///Get the playback time of the current song in the queue.
  Future<double> getPlaybackTime() async {
    final result = await playerChannel.invokeMethod('getPlaybackTime');
    return result;
  }

  ///Set the playback [time] of the current song in the queue.
  Future<void> setPlaybackTime(double time) async {
    await playerChannel.invokeMethod('setPlaybackTime', <String, dynamic>{
      'time': time,
    });
  }

  ///Skip to the beginning of the current song.
  Future<void> skipToBeginning() async {
    await playerChannel.invokeMethod('skipToBeginning');
  }

  ///Prepend [songIDs] to the queue.
  Future<void> prepend(List<String> songIDs) async {
    await playerChannel.invokeMethod('prepend', <String, dynamic>{
      'songIDs': songIDs,
    });
  }

  ///Append [songIDs] to the queue.
  Future<void> append(List<String> songIDs) async {
    await playerChannel.invokeMethod('append', <String, dynamic>{
      'songIDs': songIDs,
    });
  }

  ///Set the shuffle [mode].
  Future<void> setShuffleMode(Shuffle mode) async {
    final nativeMode = switch (mode) {
      Shuffle.off => 'off',
      Shuffle.songs => 'songs',
      Shuffle.albums => 'albums',
    };
    await playerChannel.invokeMethod('setShuffleMode', <String, dynamic>{
      'mode': nativeMode,
    });
  }

  ///Get the shuffle mode.
  Future<Shuffle> getShuffleMode() async {
    final mode = await playerChannel.invokeMethod<String>('getShuffleMode');
    return switch (mode) {
      'off' => Shuffle.off,
      'songs' => Shuffle.songs,
      'albums' => Shuffle.albums,
      _ => throw StateError('Invalid shuffle mode: $mode'),
    };
  }

  ///Set the repeat [mode].
  Future<void> setRepeatMode(Repeat mode) async {
    final nativeMode = switch (mode) {
      Repeat.none => 'none',
      Repeat.one => 'one',
      Repeat.all => 'all',
    };
    await playerChannel.invokeMethod('setRepeatMode', <String, dynamic>{
      'mode': nativeMode,
    });
  }

  ///Get the repeat mode.
  Future<Repeat> getRepeatMode() async {
    final mode = await playerChannel.invokeMethod<String>('getRepeatMode');
    return switch (mode) {
      'none' => Repeat.none,
      'one' => Repeat.one,
      'all' => Repeat.all,
      _ => throw StateError('Invalid repeat mode: $mode'),
    };
  }

  ///Fetch all songs in the Apple Music library.
  ///
  ///This method may take up significant time due to the amount of songs
  ///available on the phone.
  ///
  ///All cover art for each album is fetched when using this function.
  ///Due the amount of songs, the app may crash if the device does not have
  ///enough memory. In this case, the [coverArtSize] should be reduced.
  ///
  ///[sort] can be set to true in order to sort the artists alphabetically.
  Future<List<Artist>> getAllSongs({
    bool sort = false,
    int coverArtSize = 500,
  }) async {
    final artists = <Artist>[];
    final result = await playerChannel.invokeMethod(
      'getAllSongs',
      <String, dynamic>{'size': coverArtSize},
    );
    for (var a = 0; a < result.length; a++) {
      final resobj = Map<String, dynamic>.from(result[a]);
      final artist = Artist(albums: [], name: resobj['artist']);
      final imageData = resobj['image'];
      final image = imageData == null
          ? null
          : Uint8List.fromList(List<int>.from(imageData));
      final album = Album(
        songs: [],
        title: resobj['albumTitle'],
        albumTrackCount: resobj['albumTrackCount'] ?? 0,
        coverArt: image,
        discCount: resobj['discCount'] ?? 0,
        artistName: artist.name,
      );
      final song = Song.fromJson(resobj);
      album.songs.add(song);
      artist.albums.add(album);
      album.artistName = artist.name;
      var foundArtist = false;
      for (var i = 0; i < artists.length; i++) {
        if (artist.name == artists[i].name) {
          foundArtist = true;
          var foundAlbum = false;
          for (var j = 0; j < artists[i].albums.length; j++) {
            if (artists[i].albums[j].title == album.title) {
              //If the album does not have a cover art
              if ((artists[i].albums[j].coverArt == null &&
                      album.coverArt != null) ||
                  (artists[i].name != album.artistName)) {
                album.coverArt = artists[i].albums[j].coverArt = album.coverArt;
              }
              artists[i].albums[j].songs.add(song);
              artists[i].albums[j].songs.sort(
                    (a, b) => a.trackNumber - b.trackNumber,
                  );
              foundAlbum = true;
              break;
            }
          }
          if (!foundAlbum) {
            artists[i].albums.add(album);
            artists[i].albums.sort((a, b) => a.title.compareTo(b.title));
          }
        }
      }
      if (!foundArtist) {
        artists.add(artist);
      }
    }
    if (sort) artists.sort((a, b) => a.name.compareTo(b.name));
    return artists;
  }

  ///Retrieve information about the current playing song on the queue.
  ///
  ///Specify a [coverArtSize] to fetch the current song with the [coverArtSize].
  Future<SongInformation?> nowPlaying({int coverArtSize = 800}) async {
    final result = await playerChannel.invokeMethod(
      'nowPlaying',
      <String, dynamic>{'size': coverArtSize},
    );
    if (result == null) {
      return null;
    }
    final resobj = Map<String, dynamic>.from(result);
    final artist = Artist(albums: [], name: resobj['artist']);
    Uint8List? coverArt;
    try {
      coverArt = resobj['image'];
    } catch (_) {}
    final album = Album(
      songs: [],
      title: resobj['albumTitle'],
      albumTrackCount: resobj['albumTrackCount'] ?? 0,
      coverArt: coverArt,
      discCount: resobj['discCount'] ?? 0,
      artistName: artist.name,
    );
    final song = Song.fromJson(resobj);
    album.songs.add(song);
    artist.albums.add(album);
    album.artistName = artist.name;
    final info = SongInformation(album: album, artist: artist, song: song);
    return info;
  }

  ///Get all the playlists.
  Future<List<Playlist>?> getPlaylists() async {
    final result = await playerChannel.invokeMethod<List<dynamic>>(
      'getPlaylists',
    );
    final playlistMaps =
        result?.map((i) => Map<String, dynamic>.from(i)).toList();
    final playlists = playlistMaps
        ?.map<Playlist>(
          (i) => Playlist(
            songs: List<Song>.from(
              i['songs'].map(
                (j) => Song.fromJson(Map<String, dynamic>.from(j)),
              ),
            ),
            title: i['title'],
            playlistID: i['playlistID'].toString(),
          ),
        )
        .toList();
    return playlists;
  }

  ///Set the [volume] between 0 to 1.
  ///
  ///The audio is set using MPVolumeView, so the volume changing indicator
  ///will appear in the left side of the device on iOS.
  Future<void> setVolume(double value) async {
    await playerChannel.invokeMethod<void>('setVolume', <String, dynamic>{
      'volume': value,
    });
  }

  ///Get the volume between 0 to 1.
  Future<double?> getVolume() async {
    final volume = await playerChannel.invokeMethod<double>('getVolume');
    return volume;
  }

  ///Increment the volume by [amount].
  ///
  ///In order to decrease the volume, pass a negative value to this function.
  ///
  ///If the current volume + [amount] is over 1, the volume will be set to 1.
  ///If the current volume + [amount] is under 0, the volume will be set to 0.
  Future<void> incrementVolume(double amount) async {
    await playerChannel.invokeMethod<double>(
      'incrementVolume',
      <String, dynamic>{'amount': amount},
    );
  }

  ///Get all the genres in the Apple Music library.
  Future<List<String>> getAllGenres() async {
    final result = await playerChannel.invokeMethod('getAllGenres');
    return List<String>.from(result);
  }

  ///Get all the songs in the Apple Music library with the [genre].
  ///Specify a [coverArtSize] to fetch the current song with that [coverArtSize].
  Future<List<Song>> getSongsByGenre({
    required String genre,
    int coverArtSize = 500,
  }) async {
    final result = await playerChannel.invokeMethod<List<dynamic>>(
      'getSongsByGenre',
      <String, dynamic>{'genre': genre, 'size': coverArtSize},
    );
    final songs = <Song>[];
    if (result != null) {
      for (var i = 0; i < result.length; i++) {
        songs.add(Song.fromJson(Map<String, dynamic>.from(result[i])));
      }
    }
    return songs;
  }
}

PlayifyStatus _intToStatus(int value) {
  final index =
      PlayifyStatus.values.map((e) => e.index).toList().indexOf(value);
  if (index == -1) return PlayifyStatus.unknown;
  return PlayifyStatus.values[index];
}
