import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _storageUsageMB = 0.0;
  bool _isLoadingStorage = true;

  @override
  void initState() {
    super.initState();
    _refreshStorageUsage();
  }

  Future<void> _refreshStorageUsage() async {
    final music = context.read<MusicProvider>();
    final mb = await music.downloadService.calculateOfflineStorageMB();
    if (mounted) {
      setState(() {
        _storageUsageMB = mb;
        _isLoadingStorage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(music.tr('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Language Section
          _buildSectionHeader(music.tr('language_section')),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'ar',
                  groupValue: music.languageCode,
                  title: Text(music.tr('arabic')),
                  activeColor: theme.primaryColor,
                  onChanged: (val) {
                    if (val != null) music.setLanguage(val);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'de',
                  groupValue: music.languageCode,
                  title: Text(music.tr('german')),
                  activeColor: theme.primaryColor,
                  onChanged: (val) {
                    if (val != null) music.setLanguage(val);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: music.languageCode,
                  title: Text(music.tr('english')),
                  activeColor: theme.primaryColor,
                  onChanged: (val) {
                    if (val != null) music.setLanguage(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Theme Section
          _buildSectionHeader(music.tr('appearance')),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: theme.primaryColor,
              ),
              title: Text(music.tr('dark_mode')),
              subtitle: Text(isDark ? music.tr('enabled') : music.tr('disabled')),
              trailing: Switch.adaptive(
                value: isDark,
                activeColor: theme.primaryColor,
                onChanged: (val) {
                  music.toggleTheme();
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Offline Storage Manager
          _buildSectionHeader(music.tr('offline_storage')),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        music.tr('used_storage'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      _isLoadingStorage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '${_storageUsageMB.toStringAsFixed(1)} MB',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                                fontSize: 16,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${music.tr('downloaded_songs_count')} ${music.downloadedSongs.length} ${music.tr('tracks_count')}',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: Text(music.tr('clear_cache')),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(music.tr('confirm_delete')),
                            content: Text(music.tr('confirm_delete_msg')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(music.tr('cancel'))),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(music.tr('delete'), style: const TextStyle(color: Colors.redAccent))),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await music.downloadService.clearAllOfflineStorage();
                          for (var s in music.allSongs) {
                            s.isDownloaded = false;
                            s.localAudioPath = '';
                          }
                          await music.storageService.saveDownloadedPaths({});
                          await _refreshStorageUsage();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(music.tr('cache_cleared'))),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // About Artist & App Info
          _buildSectionHeader(music.tr('about_app')),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/greeting.jpg',
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Evin Agassi (أيفين أغاسي)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              music.tr('artist_bio'),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    music.tr('app_desc'),
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(music.tr('app_version'), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      const Text('1.1.0 (Build 2)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
