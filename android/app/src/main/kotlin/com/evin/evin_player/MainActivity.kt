package com.evin.evin_player

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.system.exitProcess

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL_NAME = "com.evin.evin_player/media_notification"
        var activeChannel: MethodChannel? = null
        var instance: MainActivity? = null

        fun sendActionToFlutter(action: String) {
            val event = when (action) {
                MediaNotificationService.ACTION_PLAY -> "play"
                MediaNotificationService.ACTION_PAUSE -> "pause"
                MediaNotificationService.ACTION_NEXT -> "next"
                MediaNotificationService.ACTION_PREV -> "prev"
                MediaNotificationService.ACTION_CLOSE_APP -> "close"
                else -> ""
            }
            if (event.isNotEmpty()) {
                activeChannel?.invokeMethod("onAction", event)
            }
        }

        fun sendSeekToFlutter(positionMs: Long) {
            activeChannel?.invokeMethod("onSeek", positionMs)
        }

        fun closeAppFromService() {
            sendActionToFlutter(MediaNotificationService.ACTION_CLOSE_APP)
            instance?.let { act ->
                act.finishAndRemoveTask()
                exitProcess(0)
            } ?: run {
                exitProcess(0)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        instance = this
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        activeChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Evin Agassi"
                    val artist = call.argument<String>("artist") ?: ""
                    val album = call.argument<String>("album") ?: ""
                    val coverFilename = call.argument<String>("coverFilename") ?: ""
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: true
                    val positionMs = call.argument<Int>("positionMs")?.toLong() ?: 0L
                    val durationMs = call.argument<Int>("durationMs")?.toLong() ?: 0L

                    val intent = Intent(this, MediaNotificationService::class.java).apply {
                        putExtra(MediaNotificationService.EXTRA_TITLE, title)
                        putExtra(MediaNotificationService.EXTRA_ARTIST, artist)
                        putExtra(MediaNotificationService.EXTRA_ALBUM, album)
                        putExtra(MediaNotificationService.EXTRA_COVER_FILENAME, coverFilename)
                        putExtra(MediaNotificationService.EXTRA_IS_PLAYING, isPlaying)
                        putExtra(MediaNotificationService.EXTRA_POSITION_MS, positionMs)
                        putExtra(MediaNotificationService.EXTRA_DURATION_MS, durationMs)
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
                    val positionMs = call.argument<Int>("positionMs")?.toLong() ?: 0L
                    val durationMs = call.argument<Int>("durationMs")?.toLong() ?: 0L

                    val intent = Intent(this, MediaNotificationService::class.java).apply {
                        putExtra(MediaNotificationService.EXTRA_IS_PLAYING, isPlaying)
                        putExtra(MediaNotificationService.EXTRA_POSITION_MS, positionMs)
                        putExtra(MediaNotificationService.EXTRA_DURATION_MS, durationMs)
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
                "closeApp" -> {
                    val intent = Intent(this, MediaNotificationService::class.java).apply {
                        action = MediaNotificationService.ACTION_STOP
                    }
                    startService(intent)
                    finishAndRemoveTask()
                    exitProcess(0)
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
        val stopIntent = Intent(this, MediaNotificationService::class.java).apply {
            action = MediaNotificationService.ACTION_STOP
        }
        startService(stopIntent)
        activeChannel = null
        instance = null
        super.onDestroy()
    }
}
