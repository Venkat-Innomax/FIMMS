import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/compliance_item.dart';

class ComplianceRepository {
  List<ComplianceItem>? _cache;

  Future<List<ComplianceItem>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw =
        await rootBundle.loadString('assets/fixtures/compliance_items.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => ComplianceItem.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  Future<List<ComplianceItem>> byFacility(String facilityId) async {
    final all = await loadAll();
    return all.where((c) => c.facilityId == facilityId).toList();
  }
}

final complianceRepositoryProvider = Provider<ComplianceRepository>(
  (ref) => ComplianceRepository(),
);
