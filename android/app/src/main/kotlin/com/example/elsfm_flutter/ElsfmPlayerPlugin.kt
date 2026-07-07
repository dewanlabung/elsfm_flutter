package com.example.elsfm_flutter

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ElsfmPlayerPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "com.elsfm.mobile/player"
        const val EVENT_CHANNEL  = "com.elsfm.mobile/player_events"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    private val exoPlayer: ExoPlayer = ExoPlayer.Builder(context)
        .build()
        .also { player ->
            player.addListener(object : Player.Listener {
                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    sendEvent("isPlaying", isPlaying)
                    if (isPlaying) startPositionTimer() else stopPositionTimer()
                }

                override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                    sendEvent("currentIndex", player.currentMediaItemIndex)
                }

                override fun onPlaybackStateChanged(state: Int) {
                    val stateStr = when (state) {
                        Player.STATE_IDLE     -> "idle"
                        Player.STATE_BUFFERING -> "loading"
                        Player.STATE_READY    -> "ready"
                        Player.STATE_ENDED    -> "ended"
                        else                  -> "idle"
                    }
                    sendEvent("state", stateStr)
                    if (state == Player.STATE_READY) {
                        val dur = player.duration.coerceAtLeast(0L)
                        sendEvent("duration", dur)
                    }
                }

                override fun onPlayerError(error: PlaybackException) {
                    sendEvent("error", error.message ?: "Playback error")
                }
            })
        }

    // ── Position timer ───────────────────────────────────────────────────────
    private var positionRunnable: Runnable? = null

    private fun startPositionTimer() {
        stopPositionTimer()
        positionRunnable = object : Runnable {
            override fun run() {
                if (exoPlayer.isPlaying) {
                    sendEvent("position", exoPlayer.currentPosition)
                    mainHandler.postDelayed(this, 300)
                }
            }
        }
        mainHandler.post(positionRunnable!!)
    }

    private fun stopPositionTimer() {
        positionRunnable?.let { mainHandler.removeCallbacks(it) }
        positionRunnable = null
    }

    // ── MethodChannel ────────────────────────────────────────────────────────
    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        mainHandler.post {
            try {
                when (call.method) {
                    "setQueue" -> {
                        val items = call.argument<List<Map<String, Any>>>("items") ?: emptyList()
                        val mediaItems = items.map { item ->
                            MediaItem.Builder()
                                .setMediaId(item["id"]?.toString() ?: "")
                                .setUri(item["url"] as String)
                                .setMediaMetadata(
                                    MediaMetadata.Builder()
                                        .setTitle(item["title"] as? CharSequence)
                                        .setArtist(item["artist"] as? CharSequence)
                                        .build()
                                )
                                .build()
                        }
                        exoPlayer.setMediaItems(mediaItems)
                        exoPlayer.prepare()
                        result.success(null)
                    }
                    "playAtIndex" -> {
                        val index = call.argument<Int>("index") ?: 0
                        exoPlayer.seekTo(index, 0L)
                        exoPlayer.play()
                        result.success(null)
                    }
                    "play"  -> { exoPlayer.play(); result.success(null) }
                    "pause" -> { exoPlayer.pause(); result.success(null) }
                    "stop"  -> { exoPlayer.stop(); stopPositionTimer(); result.success(null) }
                    "seekTo" -> {
                        val posMs = call.argument<Number>("positionMs")?.toLong() ?: 0L
                        exoPlayer.seekTo(posMs)
                        result.success(null)
                    }
                    "skipNext"     -> { exoPlayer.seekToNextMediaItem(); result.success(null) }
                    "skipPrevious" -> { exoPlayer.seekToPreviousMediaItem(); result.success(null) }
                    "setRepeatMode" -> {
                        val mode = call.argument<Int>("mode") ?: Player.REPEAT_MODE_OFF
                        exoPlayer.repeatMode = mode
                        result.success(null)
                    }
                    "setShuffleEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        exoPlayer.shuffleModeEnabled = enabled
                        result.success(null)
                    }
                    "setPlaybackSpeed" -> {
                        val speed = call.argument<Number>("speed")?.toFloat() ?: 1.0f
                        exoPlayer.setPlaybackSpeed(speed)
                        result.success(null)
                    }
                    "getPosition" -> {
                        result.success(exoPlayer.currentPosition)
                    }
                    "release" -> {
                        stopPositionTimer()
                        exoPlayer.release()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("PLAYER_ERROR", e.message, null)
            }
        }
    }

    // ── EventChannel ─────────────────────────────────────────────────────────
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        stopPositionTimer()
        eventSink = null
    }

    private fun sendEvent(type: String, value: Any) {
        mainHandler.post {
            eventSink?.success(mapOf("event" to type, "value" to value))
        }
    }
}
