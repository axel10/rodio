import 'dart:async';
import '../rust/api/simple_api.dart';
import 'audio_engine_interface.dart';

class RustAudioEngine implements AudioEngine {
  final _statusController = StreamController<AudioStatus>.broadcast();
  StreamSubscription? _subscription;

  @override
  Stream<AudioStatus> get statusStream => _statusController.stream;

  @override
  Future<void> initialize() async {
    _subscription = subscribePlaybackState().listen((state) {
      _statusController.add(AudioStatus(
        path: state.path,
        position: Duration(milliseconds: state.positionMs.toInt()),
        duration: Duration(milliseconds: state.durationMs.toInt()),
        isPlaying: state.isPlaying,
        volume: state.volume,
      ));
    });
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _statusController.close();
    await disposeAudio();
  }

  @override
  Future<void> load(String path) => loadAudioFile(path: path);

  @override
  Future<void> play() => playAudio();

  @override
  Future<void> pause() => pauseAudio();

  @override
  Future<void> seek(Duration position) =>
      seekAudioMs(positionMs: position.inMilliseconds);

  @override
  Future<void> setVolume(double volume) => setAudioVolume(volume: volume);

  @override
  Future<Duration> getDuration() async {
    final ms = await getAudioDurationMs();
    return Duration(milliseconds: ms.toInt());
  }

  @override
  Future<Duration> getCurrentPosition() async {
    final ms = await getAudioPositionMs();
    return Duration(milliseconds: ms.toInt());
  }

  @override
  Future<List<double>> getLatestFft() async {
    final data = await getLatestFft();
    return data.map((e) => e.toDouble()).toList();
  }

  @override
  Future<List<double>> getWaveform({
    required String path,
    required int expectedChunks,
    int sampleStride = 1,
  }) async {
    final data = await extractWaveformForPath(
      path: path,
      expectedChunks: BigInt.from(expectedChunks),
      sampleStride: BigInt.from(sampleStride),
    );
    return data.toList();
  }

  @override
  Future<void> setEqualizerConfig(EqualizerConfig config) =>
      setAudioEqualizerConfig(config: config);

  @override
  Future<EqualizerConfig> getEqualizerConfig() => getAudioEqualizerConfig();

  @override
  bool get supportsCrossfade => true;

  @override
  Future<void> crossfade(String path, Duration duration) =>
      crossfadeToAudioFile(
        path: path,
        durationMs: duration.inMilliseconds,
      );
}
