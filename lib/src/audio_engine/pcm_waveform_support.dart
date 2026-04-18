import 'dart:typed_data';

import '../waveform_pcm_processor.dart';

mixin PcmWaveformSupport {
  static const WaveformPcmProcessor _processor = WaveformPcmProcessor();

  Future<List<double>> waveformFromPcm({
    required String path,
    required int expectedChunks,
    int sampleStride = 0,
  }) async {
    final pcm = await getAudioPcm(path: path, sampleStride: sampleStride);
    final channels = await getAudioPcmChannelCount(path: path);
    return _processor.process(
      pcm,
      expectedChunks: expectedChunks,
      channels: channels,
    );
  }

  Future<Float32List> getAudioPcm({String? path, int sampleStride = 0});

  Future<int> getAudioPcmChannelCount({String? path});
}
