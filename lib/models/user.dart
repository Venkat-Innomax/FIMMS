/// Role hierarchy from spec §3.1–§3.3 Login Roles.
enum Role {
  // §3.1 Government Internal
  collector,
  admin, // District Inspection Cell Admin
  mandalAdmin, // Additional Collector / Nodal Officer
  mandalOfficer,
  fieldOfficer,
  inspectionSupervisor, // Inspection Officer / Supervisor

  // §3.2 Facility-Side
  facilityAdmin, // Hostel Warden / Hospital Superintendent

  // §3.3 Grievance-Side
  publicUser, // Student / Parent / Guardian
  grievanceOfficer, // Grievance Review Officer
}

extension RoleX on Role {
  String get label {
    switch (this) {
      case Role.collector:
        return 'Collector';
      case Role.admin:
        return 'District Admin';
      case Role.mandalAdmin:
        return 'Nodal Officer';
      case Role.mandalOfficer:
        return 'Mandal Officer';
      case Role.fieldOfficer:
        return 'Field Officer';
      case Role.inspectionSupervisor:
        return 'Inspection Supervisor';
      case Role.facilityAdmin:
        return 'Facility Admin';
      case Role.publicUser:
        return 'Public User';
      case Role.grievanceOfficer:
        return 'Grievance Officer';
    }
  }

  static Role fromString(String value) {
    switch (value) {
      case 'collector':
        return Role.collector;
      case 'admin':
        return Role.admin;
      case 'mandal_admin':
        return Role.mandalAdmin;
      case 'mandal_officer':
        return Role.mandalOfficer;
      case 'field_officer':
        return Role.fieldOfficer;
      case 'inspection_supervisor':
        return Role.inspectionSupervisor;
      case 'facility_admin':
        return Role.facilityAdmin;
      case 'public_user':
        return Role.publicUser;
      case 'grievance_officer':
        return Role.grievanceOfficer;
      default:
        throw ArgumentError('Unknown role: $value');
    }
  }
}

class User {
  final String id;
  final String name;
  final String designation;
  final Role role;
  final String? mandalId;
  final String? facilityId;

  const User({
    required this.id,
    required this.name,
    required this.designation,
    required this.role,
    this.mandalId,
    this.facilityId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      designation: json['designation'] as String? ?? '',
      role: RoleX.fromString(json['role'] as String),
      mandalId: json['mandal_id'] as String?,
      facilityId: json['facility_id'] as String?,
    );
  }
}
