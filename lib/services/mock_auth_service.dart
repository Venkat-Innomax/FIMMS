import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/user_repository.dart';
import '../models/user.dart';

/// Holds the current signed-in user. Null when logged out.
/// No password checks — the login screen lists preset demo users and the
/// officer picks one.
class AuthStateNotifier extends StateNotifier<User?> {
  AuthStateNotifier() : super(null);

  void signIn(User user) => state = user;
  void signOut() => state = null;
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, User?>(
  (ref) => AuthStateNotifier(),
);

/// Convenience provider for loading the preset demo users.
final demoUsersProvider = FutureProvider<List<User>>((ref) async {
  return ref.read(userRepositoryProvider).loadAll();
});
