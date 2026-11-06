import 'package:flutter/services.dart';

class NativeMediaNotification {
  static const MethodChannel _channel = MethodChannel('com.evin.evin_player/media_notification');

  static Function()? onPlay;
  static Function()? onPause;
  static Function()? onNext;
  static Function()? onPrev;
  static Function(Duration position)? onSeek;
  static Function()? onClose;

  static void init({
    Function()? playCallback,
    Function()? pauseCallback,
    Function()? nextCallback,
    Function()? prevCallback,
    Function(Duration position)? seekCallback,
    Function()? closeCallback,
  }) {
    onPlay = playCallback;
    onPause = pauseCallback;
    onNext = nextCallback;
    onPrev = prevCallback;
    onSeek = seekCallback;
    onClose = closeCallback;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final action = call.arguments as String?;
        switch (action) {
          case 'play':
            onPlay?.call();
            break;
          case 'pause':
            onPause?.call();
            break;
          case 'next':
            onNext?.call();
            break;
          case 'prev':
            onPrev?.call();
            break;
          case 'close':
            onClose?.call();
            break;
        }
      } else if (call.method == 'onSeek') {
        if (call.arguments is int) {
          final posMs = call.arguments as int;
          onSeek?.call(Duration(milliseconds: posMs));
        }
      }
    });
  }

  static Future<void> show({
    required String title,
    required String artist,
    String album = '',
    String coverFilename = '',
    required bool isPlaying,
    int positionMs = 0,
    int durationMs = 0,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'artist': artist,
        'album': album,
        'coverFilename': coverFilename,
        'isPlaying': isPlaying,
        'positionMs': positionMs,
        'durationMs': durationMs,
      });
    } catch (_) {}
  }

  static Future<void> updatePlayback({
    required bool isPlaying,
    int positionMs = 0,
    int durationMs = 0,
  }) async {
    try {
      await _channel.invokeMethod('updatePlayback', {
        'isPlaying': isPlaying,
        'positionMs': positionMs,
        'durationMs': durationMs,
      });
    } catch (_) {}
  }

  static Future<void> hide() async {
    try {
      await _channel.invokeMethod('hideNotification');
    } catch (_) {}
  }

  static Future<void> closeApp() async {
    try {
      await _channel.invokeMethod('closeApp');
    } catch (_) {}
  }

  static Future<void> shareText({required String text, String title = 'Share'}) async {
    try {
      await _channel.invokeMethod('shareText', {
        'text': text,
        'title': title,
      });
    } catch (_) {}
  }
}
