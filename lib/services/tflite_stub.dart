// Web stub for tflite_flutter.
// Selected by the conditional import in face_verification_service.dart
// when running on Flutter Web (dart.library.io is absent on web).
// All classes are hollow — the service always checks kIsWeb first.

class Interpreter {
  static Future<Interpreter> fromAsset(String _) async => Interpreter._();
  Interpreter._();
  void run(Object input, Object output) {}
  void close() {}
}

