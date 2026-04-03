import 'package:audio_service/audio_service.dart';
import 'package:audio_core/audio_core.dart';

/// A wrapper around [AudioCoreController] that implements [BaseAudioHandler] 
/// to provide Android notification bar and media controls.
class AudioCoreHandler extends BaseAudioHandler with QueueHandler {
  final AudioCoreController controller;

  AudioCoreHandler(this.controller) {
    // Listen to changes and update media state
    controller.player.addListener(_updatePlaybackState);
    controller.playlist.addListener(_updateQueue);
    controller.addListener(_updateMetadata);
    
    // Initial state sync
    _updatePlaybackState();
    _updateQueue();
    _updateMetadata();
  }

  void _updatePlaybackState() {
    final state = controller.player.currentState;
    
    // Determine processing state
    AudioProcessingState processingState;
    switch (state) {
      case PlayerState.idle:
        processingState = AudioProcessingState.idle;
        break;
      case PlayerState.buffering:
        processingState = AudioProcessingState.buffering;
        break;
      case PlayerState.ready:
      case PlayerState.playing:
      case PlayerState.paused:
        processingState = AudioProcessingState.ready;
        break;
      case PlayerState.completed:
        processingState = AudioProcessingState.completed;
        break;
      case PlayerState.error:
        processingState = AudioProcessingState.error;
        break;
    }

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (controller.player.isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: processingState,
      playing: controller.player.isPlaying,
      updatePosition: controller.player.position,
      bufferedPosition: controller.player.position,
      speed: 1.0,
      queueIndex: controller.playlist.currentIndex,
    ));
  }

  void _updateQueue() {
    final newQueue = controller.playlist.items.map((track) {
      return MediaItem(
        id: track.id,
        album: track.album ?? 'Unknown Album',
        title: track.title ?? 'Unknown Title',
        artist: track.artist ?? 'Unknown Artist',
        duration: track.duration,
        extras: track.metadata,
      );
    }).toList();
    queue.add(newQueue);
  }

  void _updateMetadata() {
    final track = controller.playlist.currentTrack;
    if (track == null) {
      mediaItem.add(null);
      return;
    }
    
    // Update mediaItem with combined info from track metadata and player live duration
    mediaItem.add(MediaItem(
      id: track.id,
      album: track.album ?? 'Unknown Album',
      title: track.title ?? (track.uri.split('/').last),
      artist: track.artist ?? 'Unknown Artist',
      duration: controller.player.duration > Duration.zero 
          ? controller.player.duration 
          : track.duration,
      extras: track.metadata,
    ));
  }

  // --- AudioHandler overrides ---

  @override
  Future<void> play() => controller.player.play();

  @override
  Future<void> pause() => controller.player.pause();

  @override
  Future<void> stop() async {
    await controller.player.stopPlayback();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => controller.player.seek(position);

  @override
  Future<void> skipToNext() => controller.playlist.playNext();

  @override
  Future<void> skipToPrevious() => controller.playlist.playPrevious();
  
  @override
  Future<void> skipToQueueItem(int index) {
    if (controller.playlist.activePlaylistId != null) {
      return controller.playlist.setActivePlaylist(
        controller.playlist.activePlaylistId!,
        startIndex: index,
        autoPlay: true,
      );
    }
    return Future.value();
  }
}
