import 'package:audio_core/audio_core.dart';
import 'package:flutter/material.dart';

class FadeDemoTab extends StatefulWidget {
  const FadeDemoTab({
    super.key,
    required this.controller,
    required this.onLoadMusicPressed,
    required this.onLoadMusicWithFadePressed,
  });

  final AudioCoreController controller;
  final Future<void> Function(FadeSettings fadeSetting) onLoadMusicPressed;
  final Future<void> Function(FadeSettings fadeSetting)
  onLoadMusicWithFadePressed;

  @override
  State<FadeDemoTab> createState() => _FadeDemoTabState();
}

class _FadeDemoTabState extends State<FadeDemoTab> {
  static const FadeSettings _noFade = FadeSettings(
    fadeOnSwitch: false,
    fadeOnPauseResume: false,
    duration: Duration.zero,
    mode: FadeMode.sequential,
  );

  FadeMode _mode = FadeMode.crossfade;
  bool _fadeOnSwitch = true;
  bool _fadeOnPauseResume = true;
  int _durationMs = 500;

  FadeSettings get _customFade => FadeSettings(
    fadeOnSwitch: _fadeOnSwitch,
    fadeOnPauseResume: _fadeOnPauseResume,
    duration: Duration(milliseconds: _durationMs),
    mode: _mode,
  );

  String _summary(FadeSettings settings) {
    final durationMs = settings.duration.inMilliseconds;
    return [
      settings.fadeOnSwitch ? 'switch:on' : 'switch:off',
      settings.fadeOnPauseResume ? 'pause:on' : 'pause:off',
      'mode:${settings.mode.name}',
      'duration:${durationMs}ms',
    ].join('  ');
  }

  Future<void> _runAction(
    Future<void> Function(FadeSettings? fadeSetting) action, {
    required bool useCustomFade,
  }) async {
    await action(useCustomFade ? _customFade : _noFade);
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Future<void> Function(FadeSettings? fadeSetting) action,
    required bool useCustomFade,
  }) {
    return FilledButton.icon(
      onPressed: () => _runAction(action, useCustomFade: useCustomFade),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = widget.controller.player.currentPath;
    final isPlaying = widget.controller.player.isPlaying;
    final currentFade = _customFade;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.blur_on, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fade Demo',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use the controls below to override fade behavior per action.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(label: Text(isPlaying ? 'Playing' : 'Paused')),
                    const SizedBox(height: 8),
                    Text(
                      currentPath ?? 'No track loaded',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.library_music,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Load Music',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Load local music files into the active playlist and use the playback buttons to test fade transitions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => widget.onLoadMusicPressed(_noFade),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Load Music Files'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            widget.onLoadMusicWithFadePressed(_customFade),
                        icon: const Icon(Icons.play_circle),
                        label: const Text('Load Music + Fade Play'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => widget.controller.resetPlaybackState(),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset Player State'),
                      ),
                      OutlinedButton.icon(
                        onPressed: currentPath == null
                            ? null
                            : () =>
                                  widget.controller.player.seek(Duration.zero),
                        icon: const Icon(Icons.replay),
                        label: const Text('Restart Track'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Custom Fade Setting',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _fadeOnSwitch,
                    title: const Text('Fade when switching songs'),
                    onChanged: (value) {
                      setState(() => _fadeOnSwitch = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _fadeOnPauseResume,
                    title: const Text('Fade when pausing / resuming'),
                    onChanged: (value) {
                      setState(() => _fadeOnPauseResume = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Mode'),
                      const SizedBox(width: 12),
                      DropdownButton<FadeMode>(
                        value: _mode,
                        items: FadeMode.values
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(mode.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _mode = value);
                        },
                      ),
                      const SizedBox(width: 24),
                      Text('Duration: ${_durationMs}ms'),
                    ],
                  ),
                  Slider(
                    value: _durationMs.toDouble(),
                    min: 0,
                    max: 3000,
                    divisions: 30,
                    label: '$_durationMs ms',
                    onChanged: (value) {
                      setState(() => _durationMs = value.round());
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _summary(currentFade),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Playback Controls',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _actionButton(
                        label: 'Prev',
                        icon: Icons.skip_previous,
                        useCustomFade: true,
                        action: (fadeSetting) => widget.controller.playlist
                            .playPrevious(fadeSetting: fadeSetting),
                      ),
                      _actionButton(
                        label: 'Prev No Fade',
                        icon: Icons.skip_previous,
                        useCustomFade: false,
                        action: (fadeSetting) => widget.controller.playlist
                            .playPrevious(fadeSetting: fadeSetting),
                      ),
                      _actionButton(
                        label: 'Play',
                        icon: Icons.play_arrow,
                        useCustomFade: true,
                        action: (fadeSetting) => widget.controller.player.play(
                          fadeSetting: fadeSetting,
                        ),
                      ),
                      _actionButton(
                        label: 'Play No Fade',
                        icon: Icons.play_arrow,
                        useCustomFade: false,
                        action: (fadeSetting) => widget.controller.player.play(
                          fadeSetting: fadeSetting,
                        ),
                      ),
                      _actionButton(
                        label: 'Pause',
                        icon: Icons.pause,
                        useCustomFade: true,
                        action: (fadeSetting) => widget.controller.player.pause(
                          fadeSetting: fadeSetting,
                        ),
                      ),
                      _actionButton(
                        label: 'Pause No Fade',
                        icon: Icons.pause,
                        useCustomFade: false,
                        action: (fadeSetting) => widget.controller.player.pause(
                          fadeSetting: fadeSetting,
                        ),
                      ),
                      _actionButton(
                        label: 'Toggle',
                        icon: Icons.swap_horiz,
                        useCustomFade: true,
                        action: (fadeSetting) => widget.controller.player
                            .togglePlayPause(fadeSetting: fadeSetting),
                      ),
                      _actionButton(
                        label: 'Toggle No Fade',
                        icon: Icons.swap_horiz,
                        useCustomFade: false,
                        action: (fadeSetting) => widget.controller.player
                            .togglePlayPause(fadeSetting: fadeSetting),
                      ),
                      _actionButton(
                        label: 'Next',
                        icon: Icons.skip_next,
                        useCustomFade: true,
                        action: (fadeSetting) => widget.controller.playlist
                            .playNext(fadeSetting: fadeSetting),
                      ),
                      _actionButton(
                        label: 'Next No Fade',
                        icon: Icons.skip_next,
                        useCustomFade: false,
                        action: (fadeSetting) => widget.controller.playlist
                            .playNext(fadeSetting: fadeSetting),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tip: the buttons marked "No Fade" explicitly pass a fadeSetting that disables transition effects, while the others use your custom fade setting.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
