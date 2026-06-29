import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

class AudioServiceHandler extends BaseAudioHandler {
  final AudioPlayer audioPlayer;
  final List<Track>? tracks;

  AudioServiceHandler(this.audioPlayer, {this.tracks}) {
    _setupAudioPlayerListeners();
  }

  void _setupAudioPlayerListeners() {
    audioPlayer.playbackEventStream.listen((_) {
      _broadcastState();
    });

    audioPlayer.currentIndexStream.listen((_) {
      _updateMediaItem();
    });
  }

  void _broadcastState() {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (audioPlayer.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: {
          MediaAction.seek,
          MediaAction.seekBackward,
          MediaAction.seekForward,
        },
        playing: audioPlayer.playing,
        processingState: switch (audioPlayer.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        updatePosition: audioPlayer.position,
        bufferedPosition: audioPlayer.bufferedPosition,
        speed: audioPlayer.speed,
      ),
    );
  }

  void _updateMediaItem() {
    final index = audioPlayer.currentIndex;
    if (index == null) {
      return;
    }

    // Get track metadata from tracks list if available
    if (tracks != null && index < tracks!.length) {
      final track = tracks![index];
      final mediaItem = MediaItem(
        id: track.id.toString(),
        title: track.name,
        artist: track.artists.isNotEmpty ? track.artists.map((a) => a.name).join(', ') : 'Unknown',
        album: track.album?.name ?? 'Unknown Album',
        duration: track.duration,
        artUri: (track.album?.image != null && track.album!.image!.isNotEmpty) 
            ? Uri.parse(track.album!.image!) 
            : null,
      );
      this.mediaItem.add(mediaItem);
    }
  }

  @override
  Future<void> play() => audioPlayer.play();

  @override
  Future<void> pause() => audioPlayer.pause();

  @override
  Future<void> stop() async {
    await audioPlayer.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => audioPlayer.seek(position);

  @override
  Future<void> skipToNext() => audioPlayer.seekToNext();

  @override
  Future<void> skipToPrevious() => audioPlayer.seekToPrevious();

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    // Note: Just audio's shuffle is a boolean at the playlist level
    // This is a placeholder for future shuffle implementation
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await audioPlayer.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all => LoopMode.all,
      AudioServiceRepeatMode.group => LoopMode.off, // Not supported by just_audio
    });
  }
}

Future<AudioHandler> initAudioService(AudioPlayer audioPlayer, {List<Track>? tracks}) async {
  final handler = AudioServiceHandler(audioPlayer, tracks: tracks);

  await AudioService.init(
    builder: () => handler,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.elsfm.app.channel.audio',
      androidNotificationChannelName: 'Music playback',
      androidNotificationOngoing: false,
      androidNotificationIcon: 'mipmap/ic_launcher',
      // Keep service alive even when app is paused (CRITICAL for background playback)
      androidStopForegroundOnPause: false,
    ),
  );

  return handler;
}
