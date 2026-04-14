import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/user_repository.dart';
import '../models/user.dart';

// ---------------------------------------------------------------------------
// Module context — set at login, persists for the session
// ---------------------------------------------------------------------------

enum AppModule { hostel, hospital }

extension AppModuleX on AppModule {
  String get label => this == AppModule.hostel ? 'Hostel' : 'Hospital';
  String get fullLabel =>
      this == AppModule.hostel ? 'Hostel Module' : 'Hospital Module';
}

/// Holds the active module chosen on the login screen.
/// Defaults to hostel. Updated before/during sign-in.
final moduleProvider = StateProvider<AppModule>((ref) => AppModule.hostel);

// ---------------------------------------------------------------------------

/// Holds the current signed-in user. Null when logged out.
class AuthStateNotifier extends StateNotifier<User?> {
  AuthStateNotifier() : super(null);

  void signIn(User user) => state = user;
  void signOut() => state = null;

  /// Authenticates a special officer by mobile number (username) and password.
  /// Returns null if credentials are invalid.
  Future<User?> signInWithCredentials(
    String username,
    String password,
    UserRepository repo,
  ) async {
    final allUsers = await repo.loadAll();
    final match = allUsers.where(
      (u) => u.username == username.trim() && u.password == password,
    );
    if (match.isEmpty) return null;
    state = match.first;
    return match.first;
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, User?>(
  (ref) => AuthStateNotifier(),
);

/// Convenience provider for loading the preset demo users.
final demoUsersProvider = FutureProvider<List<User>>((ref) async {
  return ref.read(userRepositoryProvider).loadAll();
});
