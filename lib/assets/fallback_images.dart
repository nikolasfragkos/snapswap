import 'dart:convert';
import 'dart:typed_data';

/// Embedded 1x1 PNG used as a lightweight offline fallback.
class FallbackImages {
  static final Uint8List primary = base64Decode(_fallbackPngBase64);
}

// Base64-encoded 1x1 PNG (light gray) to avoid network dependency on first load.
const String _fallbackPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMBAZ9n3WkAAAAASUVORK5CYII=';
