import MediaPlayer

// Sweyer stores source IDs in Dart's signed 64-bit int. Reinterpret Apple's
// UInt64 persistent ID so all 64 bits survive the String -> Dart int round trip.
func dartIdentifier(_ identifier: MPMediaEntityPersistentID) -> String {
    String(Int64(bitPattern: identifier))
}

// Restore the original UInt64 bit pattern before querying MediaPlayer.
func mediaIdentifier(from dartIdentifier: String) -> MPMediaEntityPersistentID? {
    guard let identifier = Int64(dartIdentifier) else {
        return nil
    }
    return UInt64(bitPattern: identifier)
}

@available(iOS 10.0, *)
extension MPMediaItem {
    ///Returns a dicationary without the image data set.
    func toDict() -> [String: Any] {
        return [
            "artist": artist ?? "",
            "albumArtist": albumArtist ?? "",
            "songTitle": title ?? "",
            "albumTitle": albumTitle ?? "",
            "trackNumber": albumTrackNumber,
            "albumTrackNumber": albumTrackNumber,
            "albumTrackCount": albumTrackCount,
            "genre": genre ?? "",
            "releaseDate": Int64((releaseDate?.timeIntervalSince1970 ?? 0) * 1000),
            "playCount": playCount,
            "discCount": discCount,
            "discNumber": discNumber,
            "isExplicitItem": isExplicitItem,
            "songID": dartIdentifier(persistentID),
            "albumID": dartIdentifier(albumPersistentID),
            "artistID": dartIdentifier(artistPersistentID),
            "albumArtistID": dartIdentifier(albumArtistPersistentID),
            "genreID": dartIdentifier(genrePersistentID),
            "dateAdded": Int64(dateAdded.timeIntervalSince1970 * 1000),
            "playbackDuration": playbackDuration
        ]
    }
}

///Update system volume
///Taken from https://stackoverflow.com/a/57449875.
///@author: https://stackoverflow.com/users/1371853/swiftboy
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView(frame: .zero)
        
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
    
    static func getVolume(completionHandler: @escaping (Float) -> Void) {
        
        let volumeView = MPVolumeView(frame: .zero)
        
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            completionHandler(slider?.value ?? 0)
        }
    }
}
