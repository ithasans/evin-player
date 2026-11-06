import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../providers/music_provider.dart';
import '../widgets/song_tile.dart';
import '../widgets/evin_cover_image.dart';

class AlbumPage extends StatelessWidget {
  final Album album;

  const AlbumPage({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final albumSongs = music.allSongs.where((s) => s.albumName == album.title).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible Modern App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                album.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  EvinCoverImage(
                    assetPath: album.assetCoverPath,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          (isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7F9)).withAlpha(220),
                          isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7F9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Album Details & Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Year: ${album.year} • ${albumSongs.length} Tracks',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Play All Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 26),
                          label: Text(music.tr('play_all'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () {
                            if (albumSongs.isNotEmpty) {
                              music.playSong(albumSongs.first, playlist: albumSongs);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Download Album Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 22),
                        label: Text(music.tr('download_album')),
                        onPressed: () {
                          for (final song in albumSongs) {
                            if (!song.isDownloaded) {
                              music.downloadSong(song);
                            }
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(music.tr('downloading_album'))),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    music.tr('album_tracks'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Track List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = albumSongs[index];
                final isPlayingThis = music.currentSong?.id == song.id;

                return SongTile(
                  song: song,
                  isPlayingThis: isPlayingThis,
                  downloadProgress: music.downloadProgress[song.id],
                  onTap: () => music.playSong(song, playlist: albumSongs),
                  onFavoriteToggle: () => music.toggleFavorite(song),
                  onDownloadTap: () {
                    if (song.isDownloaded) {
                      music.deleteDownloadedSong(song);
                    } else {
                      music.downloadSong(song);
                    }
                  },
                );
              },
              childCount: albumSongs.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
