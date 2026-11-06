class Album {
  final String id;
  final String title;
  final String year;
  final String coverUrl;
  final String coverFilename;
  int songsCount;

  Album({
    required this.id,
    required this.title,
    required this.year,
    required this.coverUrl,
    required this.coverFilename,
    this.songsCount = 0,
  });

  String get assetCoverPath {
    if (coverFilename.isNotEmpty) {
      return 'assets/covers/$coverFilename';
    }
    if (coverUrl.isNotEmpty) {
      final fn = coverUrl.split('/').last;
      if (fn.isNotEmpty) {
        return 'assets/covers/$fn';
      }
    }
    return 'assets/images/greeting.jpg';
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Evin Album',
      year: json['year'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      coverFilename: json['cover_filename'] as String? ?? '',
      songsCount: json['songs_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'cover_url': coverUrl,
      'cover_filename': coverFilename,
      'songs_count': songsCount,
    };
  }
}
