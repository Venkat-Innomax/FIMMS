import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/facility.dart';
import '../../models/mandal.dart';
import '../../services/mock_auth_service.dart';

/// Repository for facility + mandal master data. Reads static JSON fixtures
/// today; swapping to an HTTP client later is a one-function change.
class FacilityRepository {
  List<Facility>? _facilities;
  List<Mandal>? _mandals;

  Future<List<Facility>> loadFacilities() async {
    if (_facilities != null) return _facilities!;
    final raw = await rootBundle.loadString('assets/fixtures/facilities.json');
    final list = json.decode(raw) as List;
    _facilities = list
        .map((e) => Facility.fromJson(e as Map<String, dynamic>))
        .toList();
    return _facilities!;
  }

  Future<List<Mandal>> loadMandals() async {
    if (_mandals != null) return _mandals!;
    final raw = await rootBundle.loadString('assets/fixtures/mandals.json');
    final list = json.decode(raw) as List;
    _mandals =
        list.map((e) => Mandal.fromJson(e as Map<String, dynamic>)).toList();
    return _mandals!;
  }

  Future<Facility?> facilityById(String id) async {
    final list = await loadFacilities();
    for (final f in list) {
      if (f.id == id) return f;
    }
    return null;
  }

  Future<Mandal?> mandalById(String id) async {
    final list = await loadMandals();
    for (final m in list) {
      if (m.id == id) return m;
    }
    return null;
  }
}

final facilityRepositoryProvider =
    Provider<FacilityRepository>((ref) => FacilityRepository());

final facilitiesProvider = FutureProvider<List<Facility>>((ref) async {
  return ref.read(facilityRepositoryProvider).loadFacilities();
});

final mandalsProvider = FutureProvider<List<Mandal>>((ref) async {
  return ref.read(facilityRepositoryProvider).loadMandals();
});

/// Facilities filtered to the active module (hostel or hospital).
/// Re-computes whenever the user switches modules.
final moduleFacilitiesProvider = FutureProvider<List<Facility>>((ref) async {
  final all = await ref.watch(facilitiesProvider.future);
  final module = ref.watch(moduleProvider);
  final targetType = module == AppModule.hostel
      ? FacilityType.hostel
      : FacilityType.hospital;
  return all.where((f) => f.type == targetType).toList();
});
