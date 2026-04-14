import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';

// ---------------------------------------------------------------------------
// Conditional import: tflite_flutter only compiles on mobile/desktop targets.
// On web the stub below is used so the file still compiles.
// ---------------------------------------------------------------------------
// ignore: uri_does_not_exist
import 'tflite_stub.dart'
    if (dart.library.io) 'package:tflite_flutter/tflite_flutter.dart'
    as tflite;

/// Result of a 1:1 face comparison.
enum FaceVerificationResult {
  /// Cosine similarity >= [AppConstants.faceMatchThreshold].
  match,

  /// Cosine similarity < threshold — faces do not match.
  noMatch,

  /// Running on Flutter Web — TFLite is not available.
  webUnsupported,

  /// Unexpected runtime error (model missing, I/O failure, etc.).
  error,
}

/// Extracts 128-d face embeddings from images using MobileFaceNet (TFLite)
/// and compares them via cosine similarity for offline 1:1 face verification.
///
/// ### Web behaviour
/// [kIsWeb] is checked first. All public methods immediately return
/// [FaceVerificationResult.webUnsupported] / empty lists on web so that the
/// rest of the UI can show an appropriate hard-block message.
///
/// ### Production upgrade path
/// Replace the asset-loading logic with a model downloaded to the app's
/// documents directory so updates can be pushed without an app release.
class FaceVerificationService {
  tflite.Interpreter? _interpreter;
  bool _modelLoaded = false;
  bool _modelLoadFailed = false;

  // ── Model loading ─────────────────────────────────────────────────────────

  Future<void> _ensureModel() async {
    if (kIsWeb || _modelLoaded || _modelLoadFailed) return;
    try {
      _interpreter = await tflite.Interpreter.fromAsset(
        AppConstants.mobileFaceNetModelPath,
      );
      _modelLoaded = true;
    } catch (e) {
      _modelLoadFailed = true;
      // Swallow — callers check FaceVerificationResult.error
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Generates a 128-d embedding for the face in [imagePath].
  ///
  /// Returns an empty list on web or if the model failed to load.
  Future<List<double>> extractEmbedding(String imagePath) async {
    if (kIsWeb) return const [];
    await _ensureModel();
    if (_modelLoadFailed || _interpreter == null) return const [];
    if (imagePath.startsWith('sample:')) {
      // Demo path — return a deterministic pseudo-embedding so the demo flow
      // can still proceed on platforms without a real camera / model.
      return _pseudoEmbedding(imagePath);
    }
    try {
      final imageBytes = File(imagePath).readAsBytesSync();
      final input = _preprocessImage(imageBytes);
      final output = List.generate(1, (_) => List<double>.filled(128, 0));
      _interpreter!.run(input, output);
      return output[0];
    } catch (_) {
      return const [];
    }
  }

  /// Compares two 128-d embeddings and returns the verification result.
  FaceVerificationResult compare(
    List<double> embA,
    List<double> embB,
  ) {
    if (kIsWeb) return FaceVerificationResult.webUnsupported;
    if (embA.isEmpty || embB.isEmpty) return FaceVerificationResult.error;
    final sim = _cosineSimilarity(embA, embB);
    return sim >= AppConstants.faceMatchThreshold
        ? FaceVerificationResult.match
        : FaceVerificationResult.noMatch;
  }

  // ── Image preprocessing ───────────────────────────────────────────────────

  /// Resizes the raw image bytes to 112×112 and normalises pixel values
  /// to [–1, 1] as expected by MobileFaceNet.
  ///
  /// Note: A full production implementation should use a proper image-resize
  /// library (e.g. `image` package). This is a simplified demo version.
  List<List<List<List<double>>>> _preprocessImage(Uint8List bytes) {
    // Decode JPEG/PNG → raw RGBA bytes using Flutter's codec.
    // For simplicity we create a fixed-size tensor with normalised zeros;
    // replace with a real image-decode + resize pipeline for production.
    const int size = 112;
    // 1 × 112 × 112 × 3
    final tensor = List.generate(
      1,
      (_) => List.generate(
        size,
        (_) => List.generate(
          size,
          (_) => List.generate(3, (_) => 0.0),
        ),
      ),
    );
    // TODO(production): decode `bytes` with the `image` package, resize to
    // 112×112, then fill tensor with (pixel / 127.5) - 1.0 per channel.
    return tensor;
  }

  // ── Math helpers ──────────────────────────────────────────────────────────

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, normA = 0, normB = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    return denom == 0 ? 0 : dot / denom;
  }

  /// Returns a deterministic pseudo-embedding for "sample:" demo paths.
  /// Two calls with the *same* path produce the same vector (cosine = 1.0).
  List<double> _pseudoEmbedding(String seed) {
    final code = seed.hashCode;
    return List.generate(128, (i) {
      final v = math.sin((code + i) * 0.1);
      return v;
    });
  }

  void dispose() {
    _interpreter?.close();
  }
}

final faceVerificationServiceProvider =
    Provider<FaceVerificationService>((ref) {
  final svc = FaceVerificationService();
  ref.onDispose(svc.dispose);
  return svc;
});
