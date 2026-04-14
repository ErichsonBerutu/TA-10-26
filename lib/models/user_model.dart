class User {
  final String nik;
  final String nama;
  final String email;
  final String noHp;
  final String alamat;
  final String? fotoUrl;
  final DateTime? tanggalLahir;
  final String? jenisKelamin;
  final DateTime loginAt;

  const User({
    required this.nik,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.alamat,
    this.fotoUrl,
    this.tanggalLahir,
    this.jenisKelamin,
    required this.loginAt,
  });

  // Untuk update profile
  User copyWith({
    String? nik,
    String? nama,
    String? email,
    String? noHp,
    String? alamat,
    String? fotoUrl,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    DateTime? loginAt,
  }) {
    return User(
      nik: nik ?? this.nik,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      noHp: noHp ?? this.noHp,
      alamat: alamat ?? this.alamat,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      loginAt: loginAt ?? this.loginAt,
    );
  }
}
