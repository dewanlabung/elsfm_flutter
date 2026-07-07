package com.example.elsfm_flutter

import android.content.ComponentName
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter MethodChannel ↔ native Media3 bridge.
 *
 * Uses MediaController to talk to [ElsfmPlaybackService], which owns the
 * ExoPlayer and runs as a foreground service — audio survives backgrounding,
 * screen-off, and lock-screen scenarios without any extra work.
 *
 * Channel layout
 * ─────────────────────────────────────────────────
 *  MethodChannel  "com.elsfm.mobile/player"        Flutter → Native
 *    setQueue     {items: [{id,url,title,artist}]}
 *    playAtIndex  {index: int}
 *    play / pause / stop
 *    seekTo       {positionMs: int}
 *    skipNext / skipPrevious
 *    setRepeatMode     {mode: 0=off | 1=one | 2=all}
 *    setShuffleEnabled {enabled: bool}
 *    setPlaybackSpeed  {speed: double}
 *    getPosition  → int (current ms)
 *    release
 *
 *  EventChannel   "com.elsfm.mobile/player_events" Native → Flutter
 *    {event:"isPlaying",    value: bool}
 *    {event:"position",     value: long ms}
 *    {event:"duration",     value: long ms}
 *    {event:"currentIndex", value: int}
 *    {event:"state",        value: "idle"|"loading"|"ready"|"ended"}
 *    {event:"error",        value: String}
 */
class ElsfmPlayerPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "com.elsfm.mobile/player"
        const val EVENT_CHANNEL  = "com.elsfm.mobile/player_events"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var mediaController: MediaController? = null

    // ── Connect to ElsfmPlaybackService ──────────────────────────────────────
    init {
        val sessionToken = SessionToken(
            context,
            ComponentName(context, ElsfmPlaybackService::class.java)
        )
        val future = MediaController.Builder(context, sessionToken).buildAsync()
        future.addListener({
            try {
                mediaController = future.get()
                attachPlayerListener()
            } catch (e: Exception) {
                sendEvent("error", "Failed to connect to playback service: ${e.message}")
            }
        }, ContextCompat.getMainExecutor(context))
    }

    // ── Player event listener ────────────────────────────────────────────────
    private fun attachPlayerListener() {
        val controller = mediaController ?: return
        controller.addListener(object : Player.Listener {

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                sendEvent("isPlaying", isPlaying)
                if (isPlaying) startPositionTimer() else stopPositionTimer()
            }

            override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                sendEvent("currentIndex", controller.currentMediaItemIndex)
                val dur = controller.duration.coerceAtLeast(0L)
                if (dur > 0) sendEvent("duration", dur)
            }

            override fun onPlaybackStateChanged(playbackState: Int) {
                val stateStr = when (playbackState) {
                    Player.STATE_IDLE      -> "idle"
                    Player.STATE_BUFFERING -> "loading"
                    Player.STATE_READY     -> "ready"
                    Player.STATE_ENDED     -> "ended"
                    else                   -> "idle"
                }
                sendEvent("state", stateStr)
                if (playbackState == Player.STATE_READY) {
                    sendEvent("duration", controller.duration.coerceAtLeast(0L))
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                sendEvent("error", error.message ?: "Playback error")
            }
        })
    }

    // ── Position timer (every 300 ms while playing) ──────────────────────────
    private var positionRunnable: Runnable? = null

    private fun startPositionTimer() {
        stopPositionTimer()
        positionRunnable = object : Runnable {
            override fun run() {
                val ctrl = mediaController
                if (ctrl != null && ctrl.isPlaying) {
                    sendEvent("position", ctrl.currentPosition)
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

    // ── MethodChannel handler ────────────────────────────────────────────────
    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        mainHandler.post {
            val ctrl = mediaController
            if (ctrl == null && call.method != "release") {
                result.error("NOT_CONNECTED", "Player service not yet connected", null)
                return@post
            }
            try {
                when (call.method) {

                    "setQueue" -> {
                        val items = call.argument<List<Map<String, Any>>>("items")
                            ?: emptyList()
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
                        ctrl!!.setMediaItems(mediaItems)
                        ctrl.prepare()
                        result.success(null)
                    }

                    "playAtIndex" -> {
                        val index = call.argument<Int>("index") ?: 0
                        ctrl!!.seekTo(index, 0L)
                        ctrl.play()
                        result.success(null)
                    }

                    "play"  -> { ctrl!!.play();  result.success(null) }
                    "pause" -> { ctrl!!.pause(); result.success(null) }

                    "stop" -> {
                        ctrl!!.stop()
                        stopPositionTimer()
                        result.success(null)
                    }

                    "seekTo" -> {
                        val posMs = call.argument<Number>("positionMs")?.toLong() ?: 0L
                        ctrl!!.seekTo(posMs)
                        result.success(null)
                    }

                    "skipNext"     -> { ctrl!!.seekToNextMediaItem();     result.success(null) }
                    "skipPrevious" -> { ctrl!!.seekToPreviousMediaItem(); result.success(null) }

                    "setRepeatMode" -> {
                        val mode = call.argument<Int>("mode") ?: Player.REPEAT_MODE_OFF
                        ctrl!!.repeatMode = mode
                        result.success(null)
                    }

                    "setShuffleEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        ctrl!!.shuffleModeEnabled = enabled
                        result.success(null)
                    }

                    "setPlaybackSpeed" -> {
                        val speed = call.argument<Number>("speed")?.toFloat() ?: 1.0f
                        ctrl!!.setPlaybackSpeed(speed)
                        result.success(null)
                    }

                    "getPosition" -> {
                        result.success(ctrl?.currentPosition ?: 0L)
                    }

                    "release" -> {
                        stopPositionTimer()
                        mediaController?.release()
                        mediaController = null
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("PLAYER_ERROR", e.message, null)
            }
        }
    }

    // ── EventChannel handler ─────────────────────────────────────────────────
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // Emit initial state if controller is already connected
        mediaController?.let { ctrl ->
            sendEvent("isPlaying", ctrl.isPlaying)
            sendEvent("currentIndex", ctrl.currentMediaItemIndex)
            if (ctrl.duration > 0) sendEvent("duration", ctrl.duration)
            sendEvent("position", ctrl.currentPosition)
        }
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
