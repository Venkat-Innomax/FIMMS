import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/assignment.dart';

class AssignmentRepository {
  List<Assignment>? _cache;

  Future<List<Assignment>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw =
        await rootBundle.loadString('assets/fixtures/assignments.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  Future<List<Assignment>> byOfficer(String officerId) async {
    final all = await loadAll();
    return all.where((a) => a.officerId == officerId).toList();
  }

  Future<List<Assignment>> byMandal(
      String mandalId, Map<String, String> officerToMandal) async {
    final all = await loadAll();
    return all
        .where((a) => officerToMandal[a.officerId] == mandalId)
        .toList();
  }
}

final assignmentRepositoryProvider = Provider<AssignmentRepository>(
  (ref) => AssignmentRepository(),
);
