/// Role hierarchy from spec §3.1–§3.3 Login Roles.
enum Role {
  // §3.1 Government Internal
  collector,
  admin, // District Inspection Cell Admin
  mandalAdmin, // Additional Collector / Nodal Officer
  mandalOfficer,
  fieldOfficer, // Hostel field inspector
  fieldOfficerHospital, // Hospital field inspector
  inspectionSupervisor, // Inspection Officer / Supervisor / District Monitoring Admin
  welfareOfficer, // Welfare Officer — hostel compliance follow-up
  dmhoAdmin, // DMHO — district health admin
  dyDmhoAdmin, // Dy. DMHO — sub-district health admin
  departmentAdmin, // Per-department admin (BC Welfare, SC Welfare, KGBV, etc.)

  // §3.2 Facility-Side
  facilityAdmin, // Hostel Warden
  hospitalSuperintendent, // Hospital Superintendent

  // §3.3 Grievance-Side
  studentUser, // Student complaint user (roll number)
  citizenUser, // Citizen complaint user (masked identity)
  publicUser, // Legacy: Student / Parent / Guardian
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
        return 'Additional Collector';
      case Role.mandalOfficer:
        return 'Mandal Officer';
      case Role.fieldOfficer:
        return 'Field Officer (Hostel)';
      case Role.fieldOfficerHospital:
        return 'Field Officer (Hospital)';
      case Role.inspectionSupervisor:
        return 'District Monitoring Admin';
      case Role.welfareOfficer:
        return 'Welfare Officer';
      case Role.dmhoAdmin:
        return 'DMHO';
      case Role.dyDmhoAdmin:
        return 'Dy. DMHO';
      case Role.departmentAdmin:
        return 'Department Admin';
      case Role.facilityAdmin:
        return 'Hostel Warden';
      case Role.hospitalSuperintendent:
        return 'Hospital Superintendent';
      case Role.studentUser:
        return 'Student';
      case Role.citizenUser:
        return 'Citizen';
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
      case 'field_officer_hospital':
        return Role.fieldOfficerHospital;
      case 'inspection_supervisor':
        return Role.inspectionSupervisor;
      case 'welfare_officer':
        return Role.welfareOfficer;
      case 'dmho_admin':
        return Role.dmhoAdmin;
      case 'dy_dmho_admin':
        return Role.dyDmhoAdmin;
      case 'department_admin':
        return Role.departmentAdmin;
      case 'facility_admin':
        return Role.facilityAdmin;
      case 'hospital_superintendent':
        return Role.hospitalSuperintendent;
      case 'student_user':
        return Role.studentUser;
      case 'citizen_user':
        return Role.citizenUser;
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
  final String? username;
  final String? password;
  final String? department; // For departmentAdmin: 'BC Welfare', 'KGBV', etc.
  final String? moduleType; // 'hostel' | 'hospital' | null

  const User({
    required this.id,
    required this.name,
    required this.designation,
    required this.role,
    this.mandalId,
    this.facilityId,
    this.username,
    this.password,
    this.department,
    this.moduleType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      designation: json['designation'] as String? ?? '',
      role: RoleX.fromString(json['role'] as String),
      mandalId: json['mandal_id'] as String?,
      facilityId: json['facility_id'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      department: json['department'] as String?,
      moduleType: json['module_type'] as String?,
    );
  }
}
