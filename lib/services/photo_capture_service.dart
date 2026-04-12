import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Abstracts camera capture across mobile and web.
///
/// Mobile: uses [ImageSource.camera] exclusively — no gallery upload, per
/// spec §5 "Photo live capture only".
///
/// Web: falls back to a labelled sample photo because browsers can't
/// reliably force a camera-only capture across all platforms. We record
/// the photo path with the prefix `sample:` so the UI can badge it.
class PhotoCaptureService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> capture() async {
    if (kIsWeb) {
      // Demo fallback — production would enforce a desktop webcam API.
      return 'sample:demo_photo_${DateTime.now().millisecondsSinceEpoch}';
    }
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return file?.path;
    } catch (_) {
      // Camera not available (e.g. running on desktop Flutter without a
      // camera plugin). Fall back to a sample photo so the demo flow
      // keeps moving.
      return 'sample:demo_photo_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}

final photoCaptureServiceProvider =
    Provider<PhotoCaptureService>((ref) => PhotoCaptureService());
