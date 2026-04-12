/// Role hierarchy from spec §3.1 Government Internal Logins.
enum Role {
  collector,
  admin, // District Inspection Cell Admin
  mandalAdmin, // Additional Collector / Nodal Officer
  mandalOfficer,
  fieldOfficer,
}

extension RoleX on Role {
  String get label {
    switch (this) {
      case Role.collector:
        return 'Collector';
      case Role.admin:
        return 'District Admin';
      case Role.mandalAdmin:
        return 'Mandal Admin';
      case Role.mandalOfficer:
        return 'Mandal Officer';
      case Role.fieldOfficer:
        return 'Field Officer';
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

  const User({
    required this.id,
    required this.name,
    required this.designation,
    required this.role,
    this.mandalId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      designation: json['designation'] as String? ?? '',
      role: RoleX.fromString(json['role'] as String),
      mandalId: json['mandal_id'] as String?,
    );
  }
}
