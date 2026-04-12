import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';

class UserRepository {
  List<User>? _users;

  Future<List<User>> loadAll() async {
    if (_users != null) return _users!;
    final raw = await rootBundle.loadString('assets/fixtures/officers.json');
    final list = json.decode(raw) as List;
    _users =
        list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    return _users!;
  }

  Future<User?> byId(String id) async {
    final list = await loadAll();
    for (final u in list) {
      if (u.id == id) return u;
    }
    return null;
  }
}

final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository());

final usersProvider = FutureProvider<List<User>>((ref) async {
  return ref.read(userRepositoryProvider).loadAll();
});
