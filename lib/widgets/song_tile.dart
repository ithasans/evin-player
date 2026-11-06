import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isPlayingThis;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDownloadTap;
  final double? downloadProgress;

  const SongTile({
    super.key,
    required this.song,
    required this.isPlayingThis,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDownloadTap,
    this.downloadProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPlayingThis
            ? theme.primaryColor.withAlpha(isDark ? 40 : 25)
            : (isDark ? const Color(0xFF1B1B24) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlayingThis
              ? theme.primaryColor.withAlpha(120)
              : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8)),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 48,
            height: 48,
            child: song.albumCoverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.albumCoverUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: isDark ? Colors.grey[900] : Colors.grey[200],
                      child: const Icon(Icons.music_note, size: 22),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/greeting.jpg',
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'assets/images/greeting.jpg',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        title: Text(
          song.songName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isPlayingThis ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
            color: isPlayingThis ? theme.primaryColor : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (song.isDownloaded) ...[
              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                '${song.albumName} • ${song.year}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Download button / indicator
            if (downloadProgress != null)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: downloadProgress! > 0 ? downloadProgress : null,
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              )
            else if (song.isDownloaded)
              IconButton(
                icon: const Icon(Icons.download_done_rounded, color: Color(0xFF10B981), size: 22),
                tooltip: 'Downloaded',
                onPressed: onDownloadTap,
              )
            else
              IconButton(
                icon: Icon(
                  Icons.arrow_downward_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                tooltip: 'Download song',
                onPressed: onDownloadTap,
              ),

            // Favorite button
            IconButton(
              icon: Icon(
                song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: song.isFavorite ? Colors.redAccent : (isDark ? Colors.grey[500] : Colors.grey[400]),
                size: 22,
              ),
              onPressed: onFavoriteToggle,
            ),
          ],
        ),
      ),
    );
  }
}
