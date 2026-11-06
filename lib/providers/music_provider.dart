import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../services/storage_service.dart';
import '../services/download_service.dart';
import '../services/localization_service.dart';
import '../services/native_media_notification.dart';

enum RepeatMode { off, all, one }

class MusicProvider with ChangeNotifier {
  final StorageService storageService;
  final DownloadService downloadService;
  final AudioPlayer _player = AudioPlayer();

  List<Song> _allSongs = [];
  List<Album> _allAlbums = [];
  List<Song> _currentQueue = [];
  
  int _currentIndex = -1;
  Song? _currentSong;

  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.all;

  String _searchQuery = '';
  String _selectedAlbumFilter = '';
  bool _isLoading = true;

  // Real-time downloads progress map: songId -> progress (0.0 to 1.0)
  final Map<String, double> _downloadProgress = {};

  // Theme mode
  ThemeMode _themeMode = ThemeMode.dark;

  // Language code: 'ar', 'de', 'en'
  String _languageCode = 'ar';

  // Sleep timer
  Timer? _sleepTimer;
  int _sleepMinutesRemaining = 0;

  MusicProvider({
    required this.storageService,
    required this.downloadService,
  }) {
    _init();
  }

  // Getters
  bool get isLoading => _isLoading;
  Song? get currentSong => _currentSong;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  String get searchQuery => _searchQuery;
  Map<String, double> get downloadProgress => _downloadProgress;
  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  Locale get currentLocale => Locale(_languageCode);
  bool get isRtl => _languageCode == 'ar';
  String tr(String key) => L10n.get(key, _languageCode);
  int get sleepMinutesRemaining => _sleepMinutesRemaining;
  bool get hasActiveSleepTimer => _sleepMinutesRemaining > 0;

  List<Song> get allSongs => _allSongs;
  List<Album> get allAlbums => _allAlbums;

  List<Song> get filteredSongs {
    List<Song> list = _allSongs;

    if (_selectedAlbumFilter.isNotEmpty) {
      list = list.where((s) => s.albumName == _selectedAlbumFilter).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((s) =>
          s.songName.toLowerCase().contains(q) ||
          s.albumName.toLowerCase().contains(q) ||
          s.year.contains(q)).toList();
    }

    return list;
  }

  List<Song> get downloadedSongs => _allSongs.where((s) => s.isDownloaded).toList();
  List<Song> get favoriteSongs => _allSongs.where((s) => s.isFavorite).toList();

  Future<void> _init() async {
    // 1. Setup Theme & Language
    final savedTheme = storageService.getThemeMode();
    _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
    _languageCode = storageService.getLanguageCode();

    // 2. Configure global audio context for uninterrupted background playback
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ),
    );

    // 3. Initialize native media notification callbacks
    NativeMediaNotification.init(
      playCallback: () => togglePlayPause(),
      pauseCallback: () => togglePlayPause(),
      nextCallback: () => playNext(),
      prevCallback: () => playPrevious(),
      seekCallback: (pos) => seek(pos),
      closeCallback: () => exitApp(),
    );

    // 4. Setup Audio Player listeners
    _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      NativeMediaNotification.updatePlayback(
        isPlaying: state == PlayerState.playing,
        positionMs: _currentPosition.inMilliseconds,
        durationMs: _totalDuration.inMilliseconds,
      );
      notifyListeners();
    });

    _player.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });

    _player.onDurationChanged.listen((dur) {
      if (dur > Duration.zero) {
        _totalDuration = dur;
        notifyListeners();
      }
    });

    _player.onPlayerComplete.listen((_) {
      _handleSongFinished();
    });

    // 5. Load catalog data
    await _loadCatalogData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCatalogData() async {
    try {
      // Load albums
      final albumsJson = await rootBundle.loadString('assets/data/albums.json');
      final albumsList = json.decode(albumsJson) as List;
      _allAlbums = albumsList.map((j) => Album.fromJson(j)).toList();

      // Load songs
      final songsJson = await rootBundle.loadString('assets/data/songs.json');
      final songsList = json.decode(songsJson) as List;
      _allSongs = songsList.map((j) => Song.fromJson(j)).toList();

      // Restore favorites
      final favIds = storageService.getFavoriteIds();
      // Restore downloaded paths
      final downloadedPaths = storageService.getDownloadedPaths();

      for (var s in _allSongs) {
        if (favIds.contains(s.id)) {
          s.isFavorite = true;
        }
        if (downloadedPaths.containsKey(s.id)) {
          final p = downloadedPaths[s.id]!;
          if (File(p).existsSync()) {
            s.localAudioPath = p;
            s.isDownloaded = true;
          }
        }
      }

      // Count songs per album
      for (var a in _allAlbums) {
        a.songsCount = _allSongs.where((s) => s.albumName == a.title).length;
      }

      _currentQueue = List.from(_allSongs);
    } catch (e) {
      debugPrint('Error loading catalog data: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void filterByAlbum(String albumTitle) {
    if (_selectedAlbumFilter == albumTitle) {
      _selectedAlbumFilter = '';
    } else {
      _selectedAlbumFilter = albumTitle;
    }
    notifyListeners();
  }

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    if (playlist != null) {
      _currentQueue = List.from(playlist);
    } else if (_currentQueue.isEmpty) {
      _currentQueue = List.from(_allSongs);
    }

    _currentSong = song;
    _currentIndex = _currentQueue.indexWhere((s) => s.id == song.id);
    _currentPosition = Duration.zero;
    _totalDuration = Duration(seconds: song.durationSeconds);

    NativeMediaNotification.show(
      title: song.songName,
      artist: song.artistName,
      album: song.albumName,
      coverFilename: song.coverFilename,
      isPlaying: true,
      positionMs: _currentPosition.inMilliseconds,
      durationMs: _totalDuration.inMilliseconds,
    );

    notifyListeners();

    try {
      await _player.stop();

      // Check if local file exists (Offline playback)
      if (song.isDownloaded && song.localAudioPath.isNotEmpty && File(song.localAudioPath).existsSync()) {
        await _player.play(DeviceFileSource(song.localAudioPath));
      } else {
        // Stream from remote URL
        await _player.play(UrlSource(song.audioUrl));
      }

      storageService.saveLastPlayedSongId(song.id);
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentSong == null) {
      if (_allSongs.isNotEmpty) {
        await playSong(_allSongs.first);
      }
      return;
    }

    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _currentPosition = position;
    NativeMediaNotification.updatePlayback(
      isPlaying: isPlaying,
      positionMs: position.inMilliseconds,
      durationMs: _totalDuration.inMilliseconds,
    );
    notifyListeners();
  }

  Future<void> exitApp() async {
    try {
      await _player.stop();
    } catch (_) {}
    _playerState = PlayerState.stopped;
    await NativeMediaNotification.hide();
    await NativeMediaNotification.closeApp();
    SystemNavigator.pop();
    exit(0);
  }

  Future<void> playNext() async {
    if (_currentQueue.isEmpty) return;

    if (_isShuffle) {
      final randIndex = Random().nextInt(_currentQueue.length);
      await playSong(_currentQueue[randIndex]);
      return;
    }

    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _currentQueue.length) {
      nextIndex = 0;
    }
    await playSong(_currentQueue[nextIndex]);
  }

  Future<void> playPrevious() async {
    if (_currentQueue.isEmpty) return;

    if (_currentPosition.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = _currentQueue.length - 1;
    }
    await playSong(_currentQueue[prevIndex]);
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeatMode() {
    if (_repeatMode == RepeatMode.off) {
      _repeatMode = RepeatMode.all;
    } else if (_repeatMode == RepeatMode.all) {
      _repeatMode = RepeatMode.one;
    } else {
      _repeatMode = RepeatMode.off;
    }
    notifyListeners();
  }

  void _handleSongFinished() {
    if (_repeatMode == RepeatMode.one) {
      if (_currentSong != null) {
        seek(Duration.zero);
        _player.resume();
      }
    } else if (_repeatMode == RepeatMode.all) {
      playNext();
    } else {
      if (_currentIndex < _currentQueue.length - 1) {
        playNext();
      } else {
        _player.stop();
      }
    }
  }

  Future<void> toggleFavorite(Song song) async {
    song.isFavorite = !song.isFavorite;
    notifyListeners();

    final favIds = _allSongs.where((s) => s.isFavorite).map((s) => s.id).toSet();
    await storageService.saveFavoriteIds(favIds);
  }

  Future<void> downloadSong(Song song) async {
    if (song.isDownloaded) return;

    _downloadProgress[song.id] = 0.01;
    notifyListeners();

    try {
      final filename = '${song.id}_${song.songName}.mp3';
      final path = await downloadService.downloadSong(
        song.audioUrl,
        filename,
        onProgress: (p) {
          _downloadProgress[song.id] = p;
          notifyListeners();
        },
      );

      song.localAudioPath = path;
      song.isDownloaded = true;
      _downloadProgress.remove(song.id);

      final map = storageService.getDownloadedPaths();
      map[song.id] = path;
      await storageService.saveDownloadedPaths(map);
      notifyListeners();
    } catch (e) {
      _downloadProgress.remove(song.id);
      notifyListeners();
      debugPrint('Download error for ${song.songName}: $e');
    }
  }

  Future<void> deleteDownloadedSong(Song song) async {
    if (!song.isDownloaded) return;

    await downloadService.deleteSongFile(song.localAudioPath);
    song.isDownloaded = false;
    song.localAudioPath = '';

    final map = storageService.getDownloadedPaths();
    map.remove(song.id);
    await storageService.saveDownloadedPaths(map);
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    storageService.saveThemeMode(_themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void setLanguage(String code) {
    if (code == _languageCode) return;
    _languageCode = code;
    storageService.saveLanguageCode(code);
    notifyListeners();
  }

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepMinutesRemaining = minutes;
    notifyListeners();

    if (minutes > 0) {
      _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _sleepMinutesRemaining--;
        if (_sleepMinutesRemaining <= 0) {
          _player.pause();
          timer.cancel();
        }
        notifyListeners();
      });
    }
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepMinutesRemaining = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    _sleepTimer?.cancel();
    super.dispose();
  }
}
