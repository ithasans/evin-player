package com.evin.evin_player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class MediaNotificationService : Service() {

    companion object {
        const val CHANNEL_ID = "evin_media_playback_channel"
        const val NOTIFICATION_ID = 1001

        const val ACTION_UPDATE = "com.evin.evin_player.UPDATE"
        const val ACTION_STOP = "com.evin.evin_player.STOP"

        const val ACTION_PLAY = "com.evin.evin_player.PLAY"
        const val ACTION_PAUSE = "com.evin.evin_player.PAUSE"
        const val ACTION_NEXT = "com.evin.evin_player.NEXT"
        const val ACTION_PREV = "com.evin.evin_player.PREV"

        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_ARTIST = "extra_artist"
        const val EXTRA_IS_PLAYING = "extra_is_playing"

        var currentTitle = "Evin Agassi"
        var currentArtist = "Assyrian Music Archive"
        var currentIsPlaying = false
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        val action = intent.action
        if (action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        // Handle user action buttons from notification
        if (action in listOf(ACTION_PLAY, ACTION_PAUSE, ACTION_NEXT, ACTION_PREV)) {
            MainActivity.sendActionToFlutter(action ?: "")
            if (action == ACTION_PLAY) currentIsPlaying = true
            if (action == ACTION_PAUSE) currentIsPlaying = false
            updateNotification()
            return START_STICKY
        }

        // Update notification info
        if (intent.hasExtra(EXTRA_TITLE)) {
            currentTitle = intent.getStringExtra(EXTRA_TITLE) ?: currentTitle
        }
        if (intent.hasExtra(EXTRA_ARTIST)) {
            currentArtist = intent.getStringExtra(EXTRA_ARTIST) ?: currentArtist
        }
        if (intent.hasExtra(EXTRA_IS_PLAYING)) {
            currentIsPlaying = intent.getBooleanExtra(EXTRA_IS_PLAYING, currentIsPlaying)
        }

        updateNotification()
        return START_STICKY
    }

    private fun updateNotification() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(): Notification {
        // PendingIntent to reopen app when tapping notification
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Previous Action
        val prevIntent = Intent(this, MediaNotificationService::class.java).apply {
            action = ACTION_PREV
        }
        val prevPendingIntent = PendingIntent.getService(
            this,
            1,
            prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Play/Pause Action
        val toggleAction = if (currentIsPlaying) ACTION_PAUSE else ACTION_PLAY
        val toggleIntent = Intent(this, MediaNotificationService::class.java).apply {
            this.action = toggleAction
        }
        val togglePendingIntent = PendingIntent.getService(
            this,
            2,
            toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Next Action
        val nextIntent = Intent(this, MediaNotificationService::class.java).apply {
            action = ACTION_NEXT
        }
        val nextPendingIntent = PendingIntent.getService(
            this,
            3,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIcon = if (currentIsPlaying) {
            android.R.drawable.ic_media_pause
        } else {
            android.R.drawable.ic_media_play
        }
        val playPauseTitle = if (currentIsPlaying) "Pause" else "Play"

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(currentTitle)
            .setContentText(currentArtist)
            .setContentIntent(openAppPendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(currentIsPlaying)
            .setSilent(true)
            .addAction(android.R.drawable.ic_media_previous, "Previous", prevPendingIntent)
            .addAction(playPauseIcon, playPauseTitle, togglePendingIntent)
            .addAction(android.R.drawable.ic_media_next, "Next", nextPendingIntent)

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Evin Agassi Playback"
            val descriptionText = "Music playback controls and information"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
