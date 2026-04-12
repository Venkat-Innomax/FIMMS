import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/form_schema.dart';

class FormSchemaRepository {
  FormSchema? _hostel;
  FormSchema? _hospital;

  Future<FormSchema> hostelSchema() async {
    if (_hostel != null) return _hostel!;
    final raw =
        await rootBundle.loadString('assets/fixtures/hostel_form_schema.json');
    _hostel = FormSchema.fromJson(json.decode(raw) as Map<String, dynamic>);
    return _hostel!;
  }

  Future<FormSchema> hospitalSchema() async {
    if (_hospital != null) return _hospital!;
    final raw = await rootBundle
        .loadString('assets/fixtures/hospital_form_schema.json');
    _hospital = FormSchema.fromJson(json.decode(raw) as Map<String, dynamic>);
    return _hospital!;
  }
}

final formSchemaRepositoryProvider =
    Provider<FormSchemaRepository>((ref) => FormSchemaRepository());
