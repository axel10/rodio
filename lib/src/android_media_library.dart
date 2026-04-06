import 'playlist_models.dart';

/// A single media item discovered from Android's MediaStore.
class AndroidMediaLibraryEntry {
  const AndroidMediaLibraryEntry({
    required this.id,
    required this.uri,
    required this.filePath,
    required this.title,
    required this.folderPath,
    this.displayName,
    this.artist,
    this.album,
    this.durationMs,
    this.bucketDisplayName,
    this.mimeType,
  });

  final String id;
  final String uri;
  final String? filePath;
  final String title;
  final String folderPath;
  final String? displayName;
  final String? artist;
  final String? album;
  final int? durationMs;
  final String? bucketDisplayName;
  final String? mimeType;

  Duration get duration => Duration(
    milliseconds: durationMs == null
        ? 0
        : durationMs!.clamp(0, 1 << 31).toInt(),
  );

  String get label => title.trim().isEmpty
      ? (displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : (filePath ?? uri))
      : title.trim();

  AudioTrack toAudioTrack() {
    final playbackPath = filePath ?? uri;
    return AudioTrack(
      id: id,
      uri: playbackPath,
      title: label,
      artist: artist,
      album: album,
      duration: durationMs == null ? null : Duration(milliseconds: durationMs!),
      metadata: <String, Object?>{
        'isLike': false,
        'playCount': 0,
        'folderPath': folderPath,
        'mediaUri': uri,
        if (filePath != null) 'filePath': filePath,
        if (displayName != null) 'displayName': displayName,
        if (bucketDisplayName != null) 'bucketDisplayName': bucketDisplayName,
        if (mimeType != null) 'mimeType': mimeType,
      },
    );
  }

  factory AndroidMediaLibraryEntry.fromMap(Map<Object?, Object?> map) {
    return AndroidMediaLibraryEntry(
      id: map['id']?.toString() ?? '',
      uri: map['uri']?.toString() ?? '',
      filePath: map['filePath']?.toString(),
      title:
          map['title']?.toString() ??
          map['displayName']?.toString() ??
          'Unknown title',
      folderPath: _normalizeFolderPath(map['relativePath']?.toString() ?? ''),
      displayName: map['displayName']?.toString(),
      artist: map['artist']?.toString(),
      album: map['album']?.toString(),
      durationMs: (map['durationMs'] as num?)?.toInt(),
      bucketDisplayName: map['bucketDisplayName']?.toString(),
      mimeType: map['mimeType']?.toString(),
    );
  }
}

/// Strongly typed result for an Android media library scan.
class AndroidMediaLibraryScanResult {
  const AndroidMediaLibraryScanResult({
    required this.permissionGranted,
    required this.entries,
    this.errorCode,
    this.errorMessage,
  });

  final bool permissionGranted;
  final List<AndroidMediaLibraryEntry> entries;
  final String? errorCode;
  final String? errorMessage;

  bool get isSuccessful => errorCode == null;
  bool get hasEntries => entries.isNotEmpty;
}

String _normalizeFolderPath(String path) {
  final cleaned = path.replaceAll('\\', '/').trim();
  if (cleaned.isEmpty) return '';
  return cleaned.endsWith('/')
      ? cleaned.substring(0, cleaned.length - 1)
      : cleaned;
}
