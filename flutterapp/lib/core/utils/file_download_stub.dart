import 'dart:typed_data';

/// Browser-only: starts a file download. Does nothing on mobile/desktop.
Future<bool> downloadBytes(
  Uint8List bytes,
  String filename, {
  String mimeType = 'application/octet-stream',
}) async => false;
