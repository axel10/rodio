import 'dart:async';
import 'package:my_exoplayer/my_exoplayer.dart';
import '../rust/api/simple/equalizer.dart';
import 'audio_engine_interface.dart';

class AndroidAudioEngine implements AudioEngine {
  final _statusController = StreamController<AudioStatus>.broadcast();
  String? _currentPath;
  double _currentVolume = 1.0;

  @override
  Stream<AudioStatus> get statusStream => _statusController.stream;

  @override
  Future<void> initialize() async {
    MyExoplayer.setPlayerStateListener((
        {required state,        required isPlaying,
        required durationMs,
        required positionMs}) {
      _statusController.add(AudioStatus(
        path: _currentPath,
        position: Duration(milliseconds: positionMs),
        duration: Duration(milliseconds: durationMs),
        isPlaying: isPlaying,
        volume: _currentVolume,
      ));
    });
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }

  @override
  Future<void> load(String path) async {
    _currentPath = path;
    await MyExoplayer.load(path);
  }

  @override
  Future<void> play() => MyExoplayer.play();

  @override
  Future<void> pause() => MyExoplayer.pause();

  @override
  Future<void> seek(Duration position) =>
      MyExoplayer.seek(position.inMilliseconds);

  @override
  Future<void> setVolume(double volume) {
    _currentVolume = volume;
    return MyExoplayer.setVolume(volume);
  }

  @override
  Future<Duration> getDuration() async {
    final ms = await MyExoplayer.getDuration();
    return Duration(milliseconds: ms);
  }

  @override
  Future<Duration> getCurrentPosition() async {
    final ms = await MyExoplayer.getCurrentPosition();
    return Duration(milliseconds: ms);
  }

  @override
  Future<List<double>> getLatestFft() => MyExoplayer.getLatestFft();

  @override
  Future<List<double>> getWaveform({
    required String path,
    required int expectedChunks,
    int sampleStride = 1,
  }) async {
    final rawData = await MyExoplayer.getWaveform(path);
    if (rawData.isEmpty) return const [];
    
    final List<double> result = [];
    for (int i = 0; i < expectedChunks; i++) {
      final int sourceIdx = (i * rawData.length / expectedChunks).floor();
      // Normalize to 0.0 - 1.0. Amplituda typically returns 0-100.
      result.add(rawData[sourceIdx] / 100.0);
    }
    return result;
  }

  @override
  Future<void> setEqualizerConfig(EqualizerConfig config) async {
    // Android has "Advanced" (Rust-based in Exoplayer extension) and "System" EQ.
    // Assuming we use the advanced one to match Desktop behavior.
    await MyExoplayer.setCppEqualizerEnabled(config.enabled);
    await MyExoplayer.setCppEqualizerPreAmp(config.preampDb);
    await MyExoplayer.setCppEqualizerBandCount(config.bandCount);
    await MyExoplayer.setCppEqualizerConfig(
      bandGains: config.bandGainsDb.toList(),
    );
  }

  @override
  Future<EqualizerConfig> getEqualizerConfig() async {
    // Current Android implementation does not seem to have a getter for Cpp EQ config.
    // For now we return a stub or let the controller track it.
    throw UnimplementedError('getEqualizerConfig not available on Android yet');
  }

  @override
  bool get supportsCrossfade => false;

  @override
  Future<void> crossfade(String path, Duration duration) {
    throw UnsupportedError('Crossfade not supported on Android');
  }
}
