import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/complaint.dart';

class ComplaintRepository {
  List<Complaint>? _cache;

  Future<List<Complaint>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw =
        await rootBundle.loadString('assets/fixtures/complaints.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  Future<List<Complaint>> byUser(String userId) async {
    final all = await loadAll();
    return all.where((c) => c.submittedBy == userId).toList();
  }

  Future<List<Complaint>> byFacility(String facilityId) async {
    final all = await loadAll();
    return all.where((c) => c.facilityId == facilityId).toList();
  }

  Future<List<Complaint>> unassigned() async {
    final all = await loadAll();
    return all.where((c) => c.assignedTo == null).toList();
  }
}

final complaintRepositoryProvider = Provider<ComplaintRepository>(
  (ref) => ComplaintRepository(),
);

/// Mutable in-memory list of complaints, seeded from fixtures.
class ComplaintListNotifier extends StateNotifier<List<Complaint>> {
  final ComplaintRepository _repo;
  bool _loaded = false;

  ComplaintListNotifier(this._repo) : super([]);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    state = await _repo.loadAll();
  }

  Future<void> load() => _ensureLoaded();

  /// Replace a complaint by ID with an updated version.
  void update(Complaint updated) {
    state = [
      for (final c in state)
        if (c.id == updated.id) updated else c,
    ];
  }

  void add(Complaint c) {
    state = [...state, c];
  }
}

final complaintListProvider =
    StateNotifierProvider<ComplaintListNotifier, List<Complaint>>((ref) {
  final repo = ref.read(complaintRepositoryProvider);
  final notifier = ComplaintListNotifier(repo);
  notifier.load();
  return notifier;
});
