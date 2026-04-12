import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inspection.dart';

class InspectionRepository {
  List<Inspection>? _inspections;

  Future<List<Inspection>> loadAll() async {
    if (_inspections != null) return _inspections!;
    final raw = await rootBundle.loadString('assets/fixtures/inspections.json');
    final list = json.decode(raw) as List;
    _inspections = list
        .map((e) => Inspection.fromJson(e as Map<String, dynamic>))
        .toList();
    return _inspections!;
  }

  Future<Inspection?> byId(String id) async {
    final list = await loadAll();
    for (final i in list) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<Inspection?> byFacility(String facilityId) async {
    final list = await loadAll();
    try {
      return list.firstWhere((i) => i.facilityId == facilityId);
    } catch (_) {
      return null;
    }
  }

  /// Append a newly-submitted inspection to the in-memory cache.
  /// Persists only for the current session (no backend).
  void addLocal(Inspection inspection) {
    _inspections ??= [];
    _inspections!.add(inspection);
  }
}

final inspectionRepositoryProvider =
    Provider<InspectionRepository>((ref) => InspectionRepository());

final inspectionsProvider = FutureProvider<List<Inspection>>((ref) async {
  return ref.read(inspectionRepositoryProvider).loadAll();
});
