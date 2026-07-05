class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.profilePhotoUrl,
    this.studentCode,
    this.teacherCode,
  });

  final int id;
  final String name;
  final String role;
  final String? email;
  final String? profilePhotoUrl;
  final String? studentCode;
  final String? teacherCode;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final teacher = json['teacher'] as Map<String, dynamic>?;

    return AuthUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Student',
      role: json['role'] as String? ?? 'student',
      email: json['email'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      studentCode: student?['student_code'] as String?,
      teacherCode: teacher?['teacher_code'] as String?,
    );
  }
}
