package com.example.elsfm_flutter

import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService

/**
 * Foreground MediaSessionService that owns the ExoPlayer instance.
 *
 * Running audio through a service means Android keeps it alive even when
 * the Flutter UI is in the background or the screen is off. The system
 * automatically posts a media-playback notification and routes lock-screen /
 * headphone-button events through the MediaSession.
 *
 * ElsfmPlayerPlugin connects to this service via MediaController, which gives
 * it a Player-compatible interface without needing to own the ExoPlayer itself.
 */
class ElsfmPlaybackService : MediaSessionService() {

    private var mediaSession: MediaSession? = null

    override fun onCreate() {
        super.onCreate()
        val player = ExoPlayer.Builder(this).build()
        mediaSession = MediaSession.Builder(this, player).build()
    }

    override fun onGetSession(
        controllerInfo: MediaSession.ControllerInfo,
    ): MediaSession? = mediaSession

    override fun onDestroy() {
        mediaSession?.run {
            player.release()
            release()
            mediaSession = null
        }
        super.onDestroy()
    }
}
