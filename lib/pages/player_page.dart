import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/evin_cover_image.dart';
import '../providers/music_provider.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showSleepTimerDialog(BuildContext context, MusicProvider music) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                music.tr('sleep_timer_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              if (music.hasActiveSleepTimer)
                Text(
                  '${music.tr('sleep_timer_remaining_prefix')} ${music.sleepMinutesRemaining} ${music.tr('minutes')}',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _timerOption(ctx, music, 15, music.tr('sleep_timer_15m')),
                  _timerOption(ctx, music, 30, music.tr('sleep_timer_30m')),
                  _timerOption(ctx, music, 45, music.tr('sleep_timer_45m')),
                  _timerOption(ctx, music, 60, music.tr('sleep_timer_60m')),
                ],
              ),
              const SizedBox(height: 16),
              if (music.hasActiveSleepTimer)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withAlpha(40),
                    foregroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.close),
                  label: Text(music.tr('cancel_timer')),
                  onPressed: () {
                    music.cancelSleepTimer();
                    Navigator.pop(ctx);
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _timerOption(BuildContext ctx, MusicProvider music, int minutes, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () {
        music.setSleepTimer(minutes);
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${music.tr('sleep_timer_set_msg')} $label')),
        );
      },
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final currentSong = music.currentSong;

    if (currentSong == null) {
      return Scaffold(
        body: Center(child: Text(music.tr('no_track_selected'))),
      );
    }

    if (music.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _rotationController.stop();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final maxSeconds = music.totalDuration.inSeconds.toDouble();
    final currentSeconds = music.currentPosition.inSeconds.toDouble().clamp(0.0, maxSeconds > 0 ? maxSeconds : 1.0);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    children: [
                      Text(
                        music.tr('now_playing'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currentSong.albumName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      music.hasActiveSleepTimer ? Icons.timer_rounded : Icons.timer_outlined,
                      color: music.hasActiveSleepTimer ? theme.primaryColor : null,
                    ),
                    onPressed: () => _showSleepTimerDialog(context, music),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Album Art with Vinyl / Modern Glow
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: MediaQuery.of(context).size.width * 0.78,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withAlpha(isDark ? 90 : 50),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: EvinCoverImage(
                    assetPath: currentSong.assetCoverPath,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Title, Artist & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentSong.artistName} • ${currentSong.year}',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Download button
                  if (music.downloadProgress.containsKey(currentSong.id))
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        value: music.downloadProgress[currentSong.id],
                        strokeWidth: 3,
                      ),
                    )
                  else if (currentSong.isDownloaded)
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                      tooltip: 'Saved Offline',
                      onPressed: () => music.deleteDownloadedSong(currentSong),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.arrow_downward_rounded, size: 26),
                      tooltip: 'Download for Offline',
                      onPressed: () => music.downloadSong(currentSong),
                    ),

                  // Favorite toggle
                  IconButton(
                    icon: Icon(
                      currentSong.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: currentSong.isFavorite ? Colors.redAccent : Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => music.toggleFavorite(currentSong),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Seek Slider & Duration
              Column(
                children: [
                  SliderTheme(
                    data: theme.sliderTheme.copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: currentSeconds,
                      min: 0.0,
                      max: maxSeconds > 0 ? maxSeconds : 1.0,
                      onChanged: (val) {
                        music.seek(Duration(seconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(music.currentPosition),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDuration(music.totalDuration),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Player Controls (Shuffle, Prev, Play/Pause, Next, Repeat)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: music.isShuffle ? theme.primaryColor : Colors.grey,
                      size: 26,
                    ),
                    onPressed: () => music.toggleShuffle(),
                  ),

                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 40),
                    onPressed: () => music.playPrevious(),
                  ),

                  // Play/Pause Big Button
                  GestureDetector(
                    onTap: () => music.togglePlayPause(),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withAlpha(120),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        music.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),

                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 40),
                    onPressed: () => music.playNext(),
                  ),

                  // Repeat
                  IconButton(
                    icon: Icon(
                      music.repeatMode == RepeatMode.one
                          ? Icons.repeat_one_rounded
                          : (music.repeatMode == RepeatMode.all ? Icons.repeat_rounded : Icons.repeat_rounded),
                      color: music.repeatMode != RepeatMode.off ? theme.primaryColor : Colors.grey,
                      size: 26,
                    ),
                    onPressed: () => music.toggleRepeatMode(),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
