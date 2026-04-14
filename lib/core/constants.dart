/// FIMMS demo-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'FIMMS';
  static const String appTagline =
      'Field Inspection Management & Monitoring System';
  static const String districtName = 'Yadadri Bhuvanagiri';
  static const String stateName = 'Telangana';

  /// Geo-fence radius in metres (spec §5).
  static const double geofenceRadiusMeters = 100;

  /// GPS accuracy threshold; warn the officer above this value (spec §5).
  static const double gpsAccuracyWarningMeters = 50;

  /// Minimum remarks length per section (spec §5).
  static const int minRemarksChars = 10;

  /// Minimum photos required per section (spec §5).
  static const int minPhotosPerSection = 1;

  // ── Face Verification ──────────────────────────────────────────────────────

  /// Cosine similarity threshold for MobileFaceNet 1:1 face match.
  /// Values >= this are treated as a verified match.
  static const double faceMatchThreshold = 0.75;

  /// Maximum selfie verification attempts before the inspection form is
  /// permanently hard-blocked for that session.
  static const int maxSelfieAttempts = 3;

  /// Asset path for the MobileFaceNet TFLite model.
  /// See assets/models/README.md for download instructions.
  static const String mobileFaceNetModelPath =
      'assets/models/mobile_face_net.tflite';

  /// District-level map centre — roughly central Yadadri Bhuvanagiri.
  static const double districtCenterLat = 17.5418;
  static const double districtCenterLng = 78.9370;
  static const double districtInitialZoom = 10.0;
}
