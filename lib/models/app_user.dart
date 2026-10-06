/// Roles used for Role-Based Access Control (RBAC).
enum UserRole {
  student('student', 'Student'),
  classRep('class_rep', 'Class Representative'),
  teacher('teacher', 'Teacher'),
  admin('admin', 'Administrator');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromValue(String? value) => UserRole.values.firstWhere(
        (r) => r.value == value,
        orElse: () => UserRole.student,
      );

  /// Class representatives, teachers and admins can publish tech news.
  bool get canPostNews => this != UserRole.student;

  /// Teachers and admins manage the e-library.
  bool get canManageBooks => this == UserRole.teacher || this == UserRole.admin;

  /// Teachers and admins can broadcast the live bus location.
  bool get canShareBus => this == UserRole.teacher || this == UserRole.admin;

  bool get canManageUsers => this == UserRole.admin;

  /// Admins see content from every department.
  bool get seesAllDepartments => this == UserRole.admin;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.department,
    required this.role,
    this.year,
  });

  final String uid;
  final String name;
  final String department;
  final UserRole role;
  final int? year;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        name: (map['name'] as String?) ?? 'Unknown',
        department: (map['department'] as String?) ?? '',
        role: UserRole.fromValue(map['role'] as String?),
        year: (map['year'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'department': department,
        'role': role.value,
        if (year != null) 'year': year,
      };
}
