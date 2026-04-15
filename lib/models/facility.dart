import 'package:latlong2/latlong.dart';

/// Facility super-type (spec §2.1, §2.2).
enum FacilityType { hostel, hospital }

extension FacilityTypeX on FacilityType {
  String get label => this == FacilityType.hostel ? 'Hostel' : 'Hospital';
  String get apiName => this == FacilityType.hostel ? 'hostel' : 'hospital';

  static FacilityType fromString(String value) =>
      value == 'hostel' ? FacilityType.hostel : FacilityType.hospital;
}

/// Hostel sub-type codes (spec §2.1).
enum HostelSubType { sw, bc, min, tw, urs, other }

/// Hospital sub-type codes (spec §2.2).
/// DH = District Hospital, CHC = Community Health Centre,
/// PHC = Primary Health Care Centre, UPHC = Urban PHC.
enum HospitalSubType { dh, chc, phc, uphc, other }

/// Human-readable labels for sub-types from spec §2.
class SubTypeLabels {
  SubTypeLabels._();

  static const Map<String, String> labels = {
    'sw': 'TSSWR EIS (TSWREIS)',
    'bc': 'BC Welfare',
    'min': 'Minority (TMREIS)',
    'tw': 'Tribal Welfare',
    'urs': 'Urban Residential',
    'other': 'Other',
    'sc': 'SC Welfare',
    'st': 'ST Welfare',
    'kgbv': 'KGBV',
    'mjptb': 'MJPTB CWREIS',
    'tmreis': 'TMREIS',
    'tsreis': 'TSREIS',
    'tstwr': 'TSTWR EIS',
    'wcw': 'Women & Child Welfare',
    'dh': 'District Hospital',
    'chc': 'Community Health Centre',
    'phc': 'Primary Health Centre',
    'uphc': 'Urban PHC',
  };

  static String labelFor(String code) => labels[code] ?? code.toUpperCase();
}

class Facility {
  final String id;
  final String name;
  final FacilityType type;
  final String subType; // raw code: 'sw', 'dh', 'phc', etc.
  final String? gender; // Boys / Girls / Mixed (hostels only)
  final String mandalId;
  final String village;
  final LatLng location;
  final String? lastInspectionId; // nullable — not all facilities inspected
  final String? department; // e.g. "BC Welfare", "KGBV", "SC Welfare"
  final String? specialOfficerName;
  final String? specialOfficerPhone;

  const Facility({
    required this.id,
    required this.name,
    required this.type,
    required this.subType,
    required this.mandalId,
    required this.village,
    required this.location,
    this.gender,
    this.lastInspectionId,
    this.department,
    this.specialOfficerName,
    this.specialOfficerPhone,
  });

  String get subTypeLabel => SubTypeLabels.labelFor(subType);

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
        id: json['id'] as String,
        name: json['name'] as String,
        type: FacilityTypeX.fromString(json['type'] as String),
        subType: json['sub_type'] as String,
        gender: json['gender'] as String?,
        mandalId: json['mandal_id'] as String,
        village: json['village'] as String? ?? '',
        location: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        lastInspectionId: json['last_inspection_id'] as String?,
        department: json['department'] as String?,
        specialOfficerName: json['special_officer_name'] as String?,
        specialOfficerPhone: json['special_officer_phone'] as String?,
      );
}
