import 'package:flutter/services.dart';

class NativeMediaNotification {
  static const MethodChannel _channel = MethodChannel('com.evin.evin_player/media_notification');

  static Function()? onPlay;
  static Function()? onPause;
  static Function()? onNext;
  static Function()? onPrev;

  static void init({
    Function()? playCallback,
    Function()? pauseCallback,
    Function()? nextCallback,
    Function()? prevCallback,
  }) {
    onPlay = playCallback;
    onPause = pauseCallback;
    onNext = nextCallback;
    onPrev = prevCallback;

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
        }
      }
    });
  }

  static Future<void> show({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'artist': artist,
        'isPlaying': isPlaying,
      });
    } catch (_) {}
  }

  static Future<void> updatePlayback({required bool isPlaying}) async {
    try {
      await _channel.invokeMethod('updatePlayback', {
        'isPlaying': isPlaying,
      });
    } catch (_) {}
  }

  static Future<void> hide() async {
    try {
      await _channel.invokeMethod('hideNotification');
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
