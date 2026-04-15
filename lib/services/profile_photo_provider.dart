import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── State ─────────────────────────────────────────────────────────────────

/// Holds the state of the inspector's one-time profile selfie.
///
/// Once [isSet] is true it can never return to false — no photo changes
/// are permitted after the initial capture.
class ProfilePhotoState {
  /// Absolute path to the captured selfie file.
  /// Null until the photo is taken.
  final String? photoPath;

  /// 128-d face embedding produced by MobileFaceNet.
  /// Null on web or until photo is successfully processed.
  final List<double>? embedding;

  /// Whether the profile photo has been permanently set.
  /// Persisted via shared_preferences so the lock survives app restarts.
  final bool isSet;

  const ProfilePhotoState({
    this.photoPath,
    this.embedding,
    required this.isSet,
  });

  const ProfilePhotoState.initial() : photoPath = null, embedding = null, isSet = false;

  ProfilePhotoState copyWith({
    String? photoPath,
    List<double>? embedding,
    bool? isSet,
  }) =>
      ProfilePhotoState(
        photoPath: photoPath ?? this.photoPath,
        embedding: embedding ?? this.embedding,
        isSet: isSet ?? this.isSet,
      );
}

// ── SharedPreferences keys (per-user, keyed by userId) ──────────────────

String _kIsSet(String userId) => 'profile_photo_is_set_$userId';
String _kPhotoPath(String userId) => 'profile_photo_path_$userId';

// ── Notifier ──────────────────────────────────────────────────────────────

class ProfilePhotoNotifier extends StateNotifier<ProfilePhotoState> {
  final String userId;

  ProfilePhotoNotifier(this.userId) : super(const ProfilePhotoState.initial()) {
    _restore();
  }

  /// Restores the "is-set" lock flag from shared_preferences on startup.
  /// (The embedding itself is NOT persisted — it must be re-computed from the
  /// stored photo path on the next app launch. For production, persist the
  /// embedding bytes to a secure keystore instead.)
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSet = prefs.getBool(_kIsSet(userId)) ?? false;
      final path = prefs.getString(_kPhotoPath(userId));
      if (isSet) {
        state = ProfilePhotoState(
          photoPath: path,
          embedding: null, // re-computed by the profile tab on first display
          isSet: true,
        );
      }
    } catch (_) {
      // Preferences unavailable — stay with in-memory default.
    }
  }

  /// Sets the profile photo for the first time.
  ///
  /// Subsequent calls are silently ignored when [state.isSet] is already true.
  Future<void> setPhoto({
    required String path,
    required List<double> embedding,
  }) async {
    if (state.isSet) return; // immutable once set

    state = state.copyWith(
      photoPath: path,
      embedding: embedding,
      isSet: true,
    );

    // Persist the lock flag so the UI stays read-only after app restart.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsSet(userId), true);
      await prefs.setString(_kPhotoPath(userId), path);
    } catch (_) {
      // Ignore — in-memory state is still correct.
    }
  }

  /// Updates only the embedding (used when restoring from disk: the path is
  /// persisted but the embedding must be recomputed from it).
  void setEmbedding(List<double> embedding) {
    if (!state.isSet) return;
    state = state.copyWith(embedding: embedding);
  }
}

// ── Provider (family — one instance per officer userId) ─────────────────

/// Usage: `ref.watch(profilePhotoProvider(user.id))`
final profilePhotoProvider = StateNotifierProviderFamily<
    ProfilePhotoNotifier, ProfilePhotoState, String>(
  (ref, userId) => ProfilePhotoNotifier(userId),
);
