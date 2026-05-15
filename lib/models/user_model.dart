class User {
  final int id;
  final String nik;
  final String nama;
  final String tempatLahir;
  final DateTime? tanggalLahir;
  final String alamat;
  final String email;
  final String role;

  User({
    required this.id,
    required this.nik,
    required this.nama,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.alamat,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      nik: json['nik'] ?? '',
      nama: json['nama'] ?? '',
      tempatLahir: json['tempat_lahir'] ?? '',
      tanggalLahir: json['tanggal_lahir'] != null
          ? DateTime.tryParse(json['tanggal_lahir'])
          : null,
      alamat: json['alamat'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik': nik,
      'nama': nama,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir':
          tanggalLahir?.toIso8601String(),
      'alamat': alamat,
      'email': email,
      'role': role,
    };
  }

  User copyWith({
    int? id,
    String? nik,
    String? nama,
    String? tempatLahir,
    DateTime? tanggalLahir,
    String? alamat,
    String? email,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      nik: nik ?? this.nik,
      nama: nama ?? this.nama,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      alamat: alamat ?? this.alamat,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}