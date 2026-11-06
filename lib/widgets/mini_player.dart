import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'evin_cover_image.dart';
import '../providers/music_provider.dart';
import '../pages/player_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final currentSong = music.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progressRatio = (music.totalDuration.inMilliseconds > 0)
        ? (music.currentPosition.inMilliseconds / music.totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, anim1, anim2) => const PlayerPage(),
            transitionsBuilder: (context, anim1, anim2, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: anim1,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 80 : 25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear Progress Indicator along the top
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 2.5,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Album Art
                  EvinCoverImage(
                    assetPath: currentSong.assetCoverPath,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 12),

                  // Song & Artist Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            currentSong.songName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '${currentSong.artistName} • ${currentSong.albumName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Favorite Quick Button
                  IconButton(
                    icon: Icon(
                      currentSong.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: currentSong.isFavorite ? Colors.redAccent : Colors.grey,
                      size: 22,
                    ),
                    onPressed: () => music.toggleFavorite(currentSong),
                  ),

                  // Play / Pause Button
                  IconButton(
                    icon: Icon(
                      music.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: theme.primaryColor,
                      size: 38,
                    ),
                    onPressed: () => music.togglePlayPause(),
                  ),

                  // Next Button
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 28),
                    onPressed: () => music.playNext(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
