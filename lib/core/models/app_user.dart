enum AppRole { peminjam, admin, petugasSarpras }

enum UserType { mahasiswa, dosen, staf }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.userType,
  });

  final String id;
  final String name;
  final String email;
  final AppRole role;
  final UserType userType;

  bool get isBorrower => role == AppRole.peminjam;
  bool get isAdmin => role == AppRole.admin;
  bool get isOfficer => role == AppRole.petugasSarpras;

  static AppUser fromRow(Map<String, dynamic> row) {
    final roleName = row['role'] as String? ?? 'peminjam';
    final typeName = row['user_type'] as String? ?? 'mahasiswa';
    return AppUser(
      id: row['id'] as String,
      name: row['name'] as String? ?? 'Pengguna',
      email: row['email'] as String? ?? '',
      role: switch (roleName) {
        'admin' => AppRole.admin,
        'petugas_sarpras' => AppRole.petugasSarpras,
        _ => AppRole.peminjam,
      },
      userType: switch (typeName) {
        'dosen' => UserType.dosen,
        'staf' => UserType.staf,
        _ => UserType.mahasiswa,
      },
    );
  }
}
