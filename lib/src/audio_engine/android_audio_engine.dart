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
        {required playerId,
        required state,
        required isPlaying,
        required durationMs,
        required positionMs}) {
      // Only report status for the active player (the one that is not being faded out)
      if (playerId == _activePlayerId) {
        _statusController.add(AudioStatus(
          path: _currentPath,
          position: Duration(milliseconds: positionMs),
          duration: Duration(milliseconds: durationMs),
          isPlaying: isPlaying,
          volume: _currentVolume,
        ));
      }
    });
  }

  String _activePlayerId = 'main';
  String get _inactivePlayerId => _activePlayerId == 'main' ? 'crossfade' : 'main';
  EqualizerConfig? _lastConfig;

  @override
  Future<void> dispose() async {
    await _statusController.close();
    await MyExoplayer.dispose(playerId: 'main');
    await MyExoplayer.dispose(playerId: 'crossfade');
  }

  @override
  Future<void> load(String path) async {
    _currentPath = path;
    await MyExoplayer.load(path, playerId: _activePlayerId);
  }

  @override
  Future<void> play() => MyExoplayer.play(playerId: _activePlayerId);

  @override
  Future<void> pause() => MyExoplayer.pause(playerId: _activePlayerId);

  @override
  Future<void> seek(Duration position) =>
      MyExoplayer.seek(position.inMilliseconds, playerId: _activePlayerId);

  @override
  Future<void> setVolume(double volume) {
    _currentVolume = volume;
    return MyExoplayer.setVolume(volume, playerId: _activePlayerId);
  }

  @override
  Future<Duration> getDuration() async {
    final ms = await MyExoplayer.getDuration(playerId: _activePlayerId);
    return Duration(milliseconds: ms);
  }

  @override
  Future<Duration> getCurrentPosition() async {
    final ms = await MyExoplayer.getCurrentPosition(playerId: _activePlayerId);
    return Duration(milliseconds: ms);
  }

  @override
  Future<List<double>> getLatestFft() => MyExoplayer.getLatestFft(playerId: _activePlayerId);

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
    _lastConfig = config;
    await _applyConfigToPlayer(_activePlayerId, config);
  }

  Future<void> _applyConfigToPlayer(String playerId, EqualizerConfig config) async {
    await MyExoplayer.setCppEqualizerEnabled(config.enabled, playerId: playerId);
    await MyExoplayer.setCppEqualizerPreAmp(config.preampDb, playerId: playerId);
    await MyExoplayer.setCppEqualizerBandCount(config.bandCount, playerId: playerId);
    await MyExoplayer.setCppEqualizerConfig(
      bandGains: config.bandGainsDb.toList(),
      playerId: playerId,
    );
  }

  @override
  Future<EqualizerConfig> getEqualizerConfig() async {
    if (_lastConfig != null) return _lastConfig!;
    throw UnimplementedError('getEqualizerConfig not available on Android yet');
  }

  @override
  bool get supportsCrossfade => true;

  @override
  Future<void> crossfade(String path, Duration duration) async {
    final oldPlayerId = _activePlayerId;
    final newPlayerId = _inactivePlayerId;
    _currentPath = path;

    // 1. Prepare new player
    await MyExoplayer.load(path, playerId: newPlayerId);
    if (_lastConfig != null) {
      await _applyConfigToPlayer(newPlayerId, _lastConfig!);
    }
    await MyExoplayer.setVolume(0.0, playerId: newPlayerId);
    await MyExoplayer.play(playerId: newPlayerId);

    // 2. Switch active player ID so status stream starts reporting the NEW track
    _activePlayerId = newPlayerId;

    // 3. Fading loop
    const steps = 20;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      // Linear crossfade (could also use sine/cosine for constant power)
      await MyExoplayer.setVolume(_currentVolume * (1.0 - t), playerId: oldPlayerId);
      await MyExoplayer.setVolume(_currentVolume * t, playerId: newPlayerId);
      await Future.delayed(stepDuration);
    }

    // 4. Cleanup old player
    await MyExoplayer.pause(playerId: oldPlayerId);
  }
}
