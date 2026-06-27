import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../models/player_state.dart' as ps;
import '../models/track.dart';

class PlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConcatenatingAudioSource _playlist;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _playlist = ConcatenatingAudioSource(children: []);
    await _audioPlayer.setAudioSource(_playlist);
  }

  Future<void> setQueue(List<Track> tracks) async {
    _playlist.clear();
    for (final track in tracks) {
      _playlist.add(
        AudioSource.uri(
          Uri.parse(track.src),
        ),
      );
    }
  }

  Future<void> play() => _audioPlayer.play();
  Future<void> pause() => _audioPlayer.pause();
  Future<void> stop() => _audioPlayer.stop();

  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  Future<void> previous() => _audioPlayer.seekToPrevious();
  Future<void> next() => _audioPlayer.seekToNext();

  Future<void> setPlaybackRate(double rate) => _audioPlayer.setSpeed(rate);

  Future<void> setLoopMode(LoopMode mode) => _audioPlayer.setLoopMode(mode);

  void setShuffle(bool shuffle) {
    // Shuffle is managed at the playlist level for now
    // Can be extended later with custom shuffle implementation
  }

  Stream<ps.PlayerState> get playerStateStream {
    return _audioPlayer.playerStateStream.map((state) {
      return ps.PlayerState(
        queue: [],
        isPlaying: state.playing,
        isLoading: state.processingState == ProcessingState.loading,
      );
    });
  }

  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> dispose() => _audioPlayer.dispose();
}
