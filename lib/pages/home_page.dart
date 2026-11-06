import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';
import '../widgets/album_card.dart';
import 'album_page.dart';
import 'settings_page.dart';
import '../components/my_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (music.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const MyDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    elevation: 0,
                    title: _isSearching
                        ? TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: music.tr('search_hint'),
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                                fontSize: 15,
                              ),
                            ),
                            onChanged: (val) {
                              music.setSearchQuery(val);
                            },
                          )
                        : Text(music.tr('app_title')),
                    actions: [
                      IconButton(
                        icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
                        onPressed: () {
                          setState(() {
                            if (_isSearching) {
                              _searchCtrl.clear();
                              music.setSearchQuery('');
                              _isSearching = false;
                            } else {
                              _isSearching = true;
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                        onPressed: () => music.toggleTheme(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  // Hero Featured Card
                  if (!_isSearching)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor,
                              const Color(0xFF6366F1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withAlpha(80),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Artist image cutout on right
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                                child: Image.asset(
                                  'assets/images/greeting.jpg',
                                  fit: BoxFit.cover,
                                  width: 140,
                                ),
                              ),
                            ),
                            // Text & Quick Action
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    music.tr('hero_title'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${music.allSongs.length} ${music.tr('tracks_count')} • ${music.allAlbums.length} ${music.tr('albums_count')}',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(220),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: theme.primaryColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                                    label: Text(music.tr('play_shuffle'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      if (music.allSongs.isNotEmpty) {
                                        music.toggleShuffle();
                                        music.playSong(music.allSongs.first, playlist: music.allSongs);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Albums Carousel Header & List
                  if (!_isSearching)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  music.tr('albums_section'),
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${music.allAlbums.length} ${music.tr('albums_count')}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 185,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: music.allAlbums.length,
                              itemBuilder: (context, idx) {
                                final album = music.allAlbums[idx];
                                return AlbumCard(
                                  album: album,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => AlbumPage(album: album)),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                  // Tab Bar Header
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarHeaderDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: theme.primaryColor,
                        indicatorWeight: 3,
                        labelColor: theme.primaryColor,
                        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: [
                          Tab(text: '${music.tr('tab_all_songs')} (${music.filteredSongs.length})'),
                          Tab(text: '${music.tr('tab_downloaded')} (${music.downloadedSongs.length})'),
                          Tab(text: '${music.tr('tab_favorites')} (${music.favoriteSongs.length})'),
                        ],
                      ),
                      isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7F9),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: All Songs
                  _buildSongList(music.filteredSongs, music),

                  // Tab 2: Downloaded (Offline)
                  music.downloadedSongs.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.cloud_download_outlined,
                          title: music.tr('no_downloads_title'),
                          subtitle: music.tr('no_downloads_sub'),
                        )
                      : _buildSongList(music.downloadedSongs, music),

                  // Tab 3: Favorites
                  music.favoriteSongs.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.favorite_border_rounded,
                          title: music.tr('no_favorites_title'),
                          subtitle: music.tr('no_favorites_sub'),
                        )
                      : _buildSongList(music.favoriteSongs, music),
                ],
              ),
            ),

            // Persistent Mini Player at Bottom
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(List<Song> songs, MusicProvider music) {
    if (songs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.music_off_rounded,
        title: 'No songs found',
        subtitle: 'Try another search query or clear filters.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 90),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isPlayingThis = music.currentSong?.id == song.id;

        return SongTile(
          song: song,
          isPlayingThis: isPlayingThis,
          downloadProgress: music.downloadProgress[song.id],
          onTap: () => music.playSong(song, playlist: songs),
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
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.withAlpha(120)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarHeaderDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarHeaderDelegate oldDelegate) {
    return false;
  }
}
