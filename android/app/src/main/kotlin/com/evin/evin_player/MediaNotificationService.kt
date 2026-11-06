package com.evin.evin_player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.IBinder

class MediaNotificationService : Service() {

    companion object {
        const val CHANNEL_ID = "evin_media_playback_channel"
        const val NOTIFICATION_ID = 1001

        const val ACTION_UPDATE = "com.evin.evin_player.UPDATE"
        const val ACTION_STOP = "com.evin.evin_player.STOP"
        const val ACTION_CLOSE_APP = "com.evin.evin_player.CLOSE_APP"

        const val ACTION_PLAY = "com.evin.evin_player.PLAY"
        const val ACTION_PAUSE = "com.evin.evin_player.PAUSE"
        const val ACTION_NEXT = "com.evin.evin_player.NEXT"
        const val ACTION_PREV = "com.evin.evin_player.PREV"

        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_ARTIST = "extra_artist"
        const val EXTRA_ALBUM = "extra_album"
        const val EXTRA_COVER_FILENAME = "extra_cover_filename"
        const val EXTRA_IS_PLAYING = "extra_is_playing"
        const val EXTRA_POSITION_MS = "extra_position_ms"
        const val EXTRA_DURATION_MS = "extra_duration_ms"

        var currentTitle = "Evin Agassi"
        var currentArtist = "Assyrian Music Archive"
        var currentAlbum = "Classic Discography"
        var currentCoverFilename = ""
        var currentIsPlaying = false
        var currentPositionMs = 0L
        var currentDurationMs = 0L

        private var cachedBitmap: Bitmap? = null
        private var cachedCoverFilename: String = ""
    }

    private var mediaSession: MediaSession? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        initMediaSession()
    }

    private fun initMediaSession() {
        if (mediaSession != null) return
        mediaSession = MediaSession(this, "EvinPlaybackSession").apply {
            setCallback(object : MediaSession.Callback() {
                override fun onPlay() {
                    currentIsPlaying = true
                    MainActivity.sendActionToFlutter(ACTION_PLAY)
                    updateNotification()
                }

                override fun onPause() {
                    currentIsPlaying = false
                    MainActivity.sendActionToFlutter(ACTION_PAUSE)
                    updateNotification()
                }

                override fun onSkipToNext() {
                    MainActivity.sendActionToFlutter(ACTION_NEXT)
                }

                override fun onSkipToPrevious() {
                    MainActivity.sendActionToFlutter(ACTION_PREV)
                }

                override fun onSeekTo(pos: Long) {
                    currentPositionMs = pos
                    MainActivity.sendSeekToFlutter(pos)
                    updateNotification()
                }

                override fun onStop() {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                    MainActivity.closeAppFromService()
                }
            })
            isActive = true
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        val action = intent.action
        if (action == ACTION_STOP) {
            mediaSession?.isActive = false
            mediaSession?.release()
            mediaSession = null
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        if (action == ACTION_CLOSE_APP) {
            mediaSession?.isActive = false
            mediaSession?.release()
            mediaSession = null
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            MainActivity.closeAppFromService()
            return START_NOT_STICKY
        }

        // Handle user action buttons from notification
        if (action in listOf(ACTION_PLAY, ACTION_PAUSE, ACTION_NEXT, ACTION_PREV)) {
            MainActivity.sendActionToFlutter(action ?: "")
            if (action == ACTION_PLAY) currentIsPlaying = true
            if (action == ACTION_PAUSE) currentIsPlaying = false
            updateNotification()
            return START_NOT_STICKY
        }

        // Update notification info
        if (intent.hasExtra(EXTRA_TITLE)) {
            currentTitle = intent.getStringExtra(EXTRA_TITLE) ?: currentTitle
        }
        if (intent.hasExtra(EXTRA_ARTIST)) {
            currentArtist = intent.getStringExtra(EXTRA_ARTIST) ?: currentArtist
        }
        if (intent.hasExtra(EXTRA_ALBUM)) {
            currentAlbum = intent.getStringExtra(EXTRA_ALBUM) ?: currentAlbum
        }
        if (intent.hasExtra(EXTRA_COVER_FILENAME)) {
            currentCoverFilename = intent.getStringExtra(EXTRA_COVER_FILENAME) ?: currentCoverFilename
        }
        if (intent.hasExtra(EXTRA_IS_PLAYING)) {
            currentIsPlaying = intent.getBooleanExtra(EXTRA_IS_PLAYING, currentIsPlaying)
        }
        if (intent.hasExtra(EXTRA_POSITION_MS)) {
            currentPositionMs = intent.getLongExtra(EXTRA_POSITION_MS, currentPositionMs)
        }
        if (intent.hasExtra(EXTRA_DURATION_MS)) {
            currentDurationMs = intent.getLongExtra(EXTRA_DURATION_MS, currentDurationMs)
        }

        updateNotification()
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        mediaSession?.isActive = false
        mediaSession?.release()
        mediaSession = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        mediaSession?.isActive = false
        mediaSession?.release()
        mediaSession = null
        super.onDestroy()
    }

    private fun loadArtworkBitmap(): Bitmap {
        if (cachedCoverFilename == currentCoverFilename && cachedBitmap != null) {
            return cachedBitmap!!
        }

        var bitmap: Bitmap? = null
        if (currentCoverFilename.isNotEmpty()) {
            try {
                assets.open("flutter_assets/assets/covers/$currentCoverFilename").use { stream ->
                    bitmap = BitmapFactory.decodeStream(stream)
                }
            } catch (_: Exception) {}
        }

        if (bitmap == null) {
            try {
                assets.open("flutter_assets/assets/images/greeting.jpg").use { stream ->
                    bitmap = BitmapFactory.decodeStream(stream)
                }
            } catch (_: Exception) {}
        }

        if (bitmap == null) {
            bitmap = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        }

        cachedBitmap = bitmap
        cachedCoverFilename = currentCoverFilename
        return bitmap!!
    }

    private fun updateNotification() {
        val cover = loadArtworkBitmap()

        // Update MediaSession metadata and playback state
        mediaSession?.let { session ->
            val metadata = MediaMetadata.Builder()
                .putString(MediaMetadata.METADATA_KEY_TITLE, currentTitle)
                .putString(MediaMetadata.METADATA_KEY_ARTIST, currentArtist)
                .putString(MediaMetadata.METADATA_KEY_ALBUM, currentAlbum)
                .putLong(MediaMetadata.METADATA_KEY_DURATION, currentDurationMs)
                .putBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART, cover)
                .putBitmap(MediaMetadata.METADATA_KEY_ART, cover)
                .putBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON, cover)
                .build()
            session.setMetadata(metadata)

            val state = if (currentIsPlaying) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED
            val speed = if (currentIsPlaying) 1.0f else 0.0f
            val playbackState = PlaybackState.Builder()
                .setActions(
                    PlaybackState.ACTION_PLAY or
                    PlaybackState.ACTION_PAUSE or
                    PlaybackState.ACTION_PLAY_PAUSE or
                    PlaybackState.ACTION_SKIP_TO_NEXT or
                    PlaybackState.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackState.ACTION_SEEK_TO or
                    PlaybackState.ACTION_STOP
                )
                .setState(state, currentPositionMs, speed)
                .build()
            session.setPlaybackState(playbackState)
        }

        val notification = buildNotification(cover)
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

    private fun buildNotification(coverBitmap: Bitmap): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val prevIntent = Intent(this, MediaNotificationService::class.java).apply {
            action = ACTION_PREV
        }
        val prevPendingIntent = PendingIntent.getService(
            this,
            1,
            prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val toggleAction = if (currentIsPlaying) ACTION_PAUSE else ACTION_PLAY
        val toggleIntent = Intent(this, MediaNotificationService::class.java).apply {
            action = toggleAction
        }
        val togglePendingIntent = PendingIntent.getService(
            this,
            2,
            toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val nextIntent = Intent(this, MediaNotificationService::class.java).apply {
            action = ACTION_NEXT
        }
        val nextPendingIntent = PendingIntent.getService(
            this,
            3,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val closeIntent = Intent(this, MediaNotificationService::class.java).apply {
            action = ACTION_CLOSE_APP
        }
        val closePendingIntent = PendingIntent.getService(
            this,
            4,
            closeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIcon = if (currentIsPlaying) {
            android.R.drawable.ic_media_pause
        } else {
            android.R.drawable.ic_media_play
        }
        val playPauseTitle = if (currentIsPlaying) "Pause" else "Play"

        // Build native Notification with MediaStyle
        val mediaStyle = Notification.MediaStyle()
            .setShowActionsInCompactView(0, 1, 2)

        mediaSession?.let {
            mediaStyle.setMediaSession(it.sessionToken)
        }

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setLargeIcon(coverBitmap)
            .setContentTitle(currentTitle)
            .setContentText(currentArtist)
            .setSubText(currentAlbum)
            .setContentIntent(openAppPendingIntent)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(currentIsPlaying)
            .setColor(0xFFFFB300.toInt())
            .setColorized(true)
            .setStyle(mediaStyle)
            .addAction(
                Notification.Action.Builder(
                    android.R.drawable.ic_media_previous,
                    "Previous",
                    prevPendingIntent
                ).build()
            )
            .addAction(
                Notification.Action.Builder(
                    playPauseIcon,
                    playPauseTitle,
                    togglePendingIntent
                ).build()
            )
            .addAction(
                Notification.Action.Builder(
                    android.R.drawable.ic_media_next,
                    "Next",
                    nextPendingIntent
                ).build()
            )
            .addAction(
                Notification.Action.Builder(
                    android.R.drawable.ic_menu_close_clear_cancel,
                    "Close",
                    closePendingIntent
                ).build()
            )

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
