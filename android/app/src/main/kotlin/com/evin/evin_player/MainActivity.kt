package com.evin.evin_player

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL_NAME = "com.evin.evin_player/media_notification"
        var activeChannel: MethodChannel? = null

        fun sendActionToFlutter(action: String) {
            val event = when (action) {
                MediaNotificationService.ACTION_PLAY -> "play"
                MediaNotificationService.ACTION_PAUSE -> "pause"
                MediaNotificationService.ACTION_NEXT -> "next"
                MediaNotificationService.ACTION_PREV -> "prev"
                else -> ""
            }
            if (event.isNotEmpty()) {
                activeChannel?.invokeMethod("onAction", event)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        activeChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Evin Agassi"
                    val artist = call.argument<String>("artist") ?: ""
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: true

                    val intent = Intent(this, MediaNotificationService::class.java).apply {
                        putExtra(MediaNotificationService.EXTRA_TITLE, title)
                        putExtra(MediaNotificationService.EXTRA_ARTIST, artist)
                        putExtra(MediaNotificationService.EXTRA_IS_PLAYING, isPlaying)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "updatePlayback" -> {
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val intent = Intent(this, MediaNotificationService::class.java).apply {
                        putExtra(MediaNotificationService.EXTRA_IS_PLAYING, isPlaying)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "hideNotification" -> {
                    val intent = Intent(this, MediaNotificationService::class.java).apply {
                        action = MediaNotificationService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                "shareText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val title = call.argument<String>("title") ?: "Share"
                    val shareIntent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    startActivity(Intent.createChooser(shareIntent, title))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        activeChannel = null
        super.onDestroy()
    }
}
