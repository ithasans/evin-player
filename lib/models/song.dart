class Song {
  final String id;
  final String songName;
  final String artistName;
  final String albumName;
  final String year;
  final String audioUrl;
  final String albumCoverUrl;
  final int durationSeconds;
  String localAudioPath;
  String localCoverPath;
  bool isDownloaded;
  bool isFavorite;

  Song({
    required this.id,
    required this.songName,
    required this.artistName,
    required this.albumName,
    required this.year,
    required this.audioUrl,
    required this.albumCoverUrl,
    this.durationSeconds = 240,
    this.localAudioPath = '',
    this.localCoverPath = '',
    this.isDownloaded = false,
    this.isFavorite = false,
  });

  String get coverFilename {
    if (albumCoverUrl.isEmpty) return '';
    final uri = Uri.tryParse(albumCoverUrl);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return albumCoverUrl.split('/').last;
  }

  String get assetCoverPath {
    final fn = coverFilename;
    if (fn.isNotEmpty) {
      return 'assets/covers/$fn';
    }
    return 'assets/images/greeting.jpg';
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String? ?? '',
      songName: json['song_name'] as String? ?? 'Unknown Track',
      artistName: json['artist_name'] as String? ?? 'Evin Agassi',
      albumName: json['album_name'] as String? ?? 'General Album',
      year: json['year'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
      albumCoverUrl: json['album_cover_url'] as String? ?? '',
      durationSeconds: json['duration_seconds'] as int? ?? 240,
      localAudioPath: json['local_audio_path'] as String? ?? '',
      localCoverPath: json['local_cover_path'] as String? ?? '',
      isDownloaded: json['is_downloaded'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'song_name': songName,
      'artist_name': artistName,
      'album_name': albumName,
      'year': year,
      'audio_url': audioUrl,
      'album_cover_url': albumCoverUrl,
      'duration_seconds': durationSeconds,
      'local_audio_path': localAudioPath,
      'local_cover_path': localCoverPath,
      'is_downloaded': isDownloaded,
      'is_favorite': isFavorite,
    };
  }

  Song copyWith({
    String? localAudioPath,
    String? localCoverPath,
    bool? isDownloaded,
    bool? isFavorite,
  }) {
    return Song(
      id: id,
      songName: songName,
      artistName: artistName,
      albumName: albumName,
      year: year,
      audioUrl: audioUrl,
      albumCoverUrl: albumCoverUrl,
      durationSeconds: durationSeconds,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      localCoverPath: localCoverPath ?? this.localCoverPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
