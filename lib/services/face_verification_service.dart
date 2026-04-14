import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

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

  /// Model file missing or failed to load.
  modelNotLoaded,

  /// Unexpected runtime error (I/O failure, decode failure, etc.).
  error,
}

/// Extracts 128-d face embeddings from images using MobileFaceNet (TFLite)
/// and compares them via cosine similarity for offline 1:1 face verification.
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
    } catch (_) {
      _modelLoadFailed = true;
    }
  }

  bool get isModelLoaded => _modelLoaded;
  bool get isModelMissing => _modelLoadFailed;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Generates a 128-d embedding for the face in [imagePath].
  /// Returns an empty list if the model is unavailable or image decode fails.
  Future<List<double>> extractEmbedding(String imagePath) async {
    if (kIsWeb) return const [];
    await _ensureModel();
    if (_modelLoadFailed || _interpreter == null) return const [];

    if (imagePath.startsWith('sample:')) {
      return _pseudoEmbedding(imagePath);
    }

    try {
      final imageBytes = File(imagePath).readAsBytesSync();
      final inputFloat = _preprocessImage(imageBytes);
      if (inputFloat == null) return const [];

      // Output: [1, 128] — one batch, 128-d embedding.
      final outputData = List.generate(1, (_) => List<double>.filled(128, 0.0));
      _interpreter!.run(inputFloat, outputData);
      return outputData[0];
    } catch (_) {
      return const [];
    }
  }

  /// Compares two 128-d embeddings and returns the verification result.
  FaceVerificationResult compare(List<double> embA, List<double> embB) {
    if (kIsWeb) return FaceVerificationResult.webUnsupported;
    if (_modelLoadFailed) return FaceVerificationResult.modelNotLoaded;
    if (embA.isEmpty || embB.isEmpty) return FaceVerificationResult.error;
    final sim = _cosineSimilarity(embA, embB);
    return sim >= AppConstants.faceMatchThreshold
        ? FaceVerificationResult.match
        : FaceVerificationResult.noMatch;
  }

  // ── Image preprocessing ───────────────────────────────────────────────────

  /// Decodes bytes, resizes to 112×112, and returns a flat [Float32List] of
  /// shape [1 × 112 × 112 × 3] normalised to [–1, 1] as MobileFaceNet expects.
  ///
  /// Uses (pixel − 127.5) / 128.0 which matches the training normalisation
  /// used by the sirius-ai/MobileFaceNet_TF model family.
  ///
  /// Returns null if the image cannot be decoded.
  Float32List? _preprocessImage(Uint8List bytes) {
    const int size = 112;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final resized = img.copyResize(
      decoded,
      width: size,
      height: size,
      interpolation: img.Interpolation.linear,
    );

    // Flat layout: [1, 112, 112, 3] — row-major, RGB order.
    final float32 = Float32List(size * size * 3);
    int idx = 0;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = resized.getPixel(x, y);
        float32[idx++] = (pixel.r.toDouble() - 127.5) / 128.0;
        float32[idx++] = (pixel.g.toDouble() - 127.5) / 128.0;
        float32[idx++] = (pixel.b.toDouble() - 127.5) / 128.0;
      }
    }
    return float32;
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

  /// Deterministic pseudo-embedding for "sample:" demo paths.
  List<double> _pseudoEmbedding(String seed) {
    final code = seed.hashCode;
    return List.generate(128, (i) => math.sin((code + i) * 0.1));
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
