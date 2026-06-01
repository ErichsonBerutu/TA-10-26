class User {
  final int id;
  final String nik;
  final String noKk;
  final String nama;
  final String tempatLahir;
  final DateTime? tanggalLahir;
  final String alamat;
  final String email;
  final String role;
  final String agama;

  // Field tambahan untuk autofill form pengajuan surat
  final String jenisKelamin; // L / P atau Laki-laki / Perempuan
  final String noKtp;        // Nomor KTP (bisa sama dengan NIK)
  final String suku;         // Suku / Etnis
  final String namaAyah;     // Nama Ayah
  final String namaIbu;      // Nama Ibu

  User({
    required this.id,
    required this.nik,
    required this.noKk,
    required this.nama,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.alamat,
    required this.email,
    required this.role,
    required this.agama,
    this.jenisKelamin = '',
    this.noKtp = '',
    this.suku = '',
    this.namaAyah = '',
    this.namaIbu = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      nik: json['nik'] ?? '',
      noKk: json['no_kk'] ?? json['kk'] ?? json['no_kartu_keluarga'] ?? '',
      nama: json['nama'] ?? json['name'] ?? '',
      tempatLahir: json['tempat_lahir'] ?? '',
      tanggalLahir: json['tanggal_lahir'] != null
          ? DateTime.tryParse(json['tanggal_lahir'])
          : null,
      alamat: json['alamat'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      agama: json['agama'] ?? '',
      jenisKelamin: json['jenis_kelamin'] ?? json['kelamin'] ?? json['gender'] ?? '',
      noKtp: json['no_ktp'] ?? json['nomor_ktp'] ?? json['ktp'] ?? json['nik'] ?? '',
      suku: json['suku'] ?? json['etnis'] ?? '',
      namaAyah: json['nama_ayah'] ?? json['ayah'] ?? '',
      namaIbu: json['nama_ibu'] ?? json['ibu'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik': nik,
      'no_kk': noKk,
      'nama': nama,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir': tanggalLahir?.toIso8601String(),
      'alamat': alamat,
      'email': email,
      'role': role,
      'agama': agama,
      'jenis_kelamin': jenisKelamin,
      'no_ktp': noKtp,
      'suku': suku,
      'nama_ayah': namaAyah,
      'nama_ibu': namaIbu,
    };
  }

  User copyWith({
    int? id,
    String? nik,
    String? noKk,
    String? nama,
    String? tempatLahir,
    DateTime? tanggalLahir,
    String? alamat,
    String? email,
    String? role,
    String? agama,
    String? jenisKelamin,
    String? noKtp,
    String? suku,
    String? namaAyah,
    String? namaIbu,
  }) {
    return User(
      id: id ?? this.id,
      nik: nik ?? this.nik,
      noKk: noKk ?? this.noKk,
      nama: nama ?? this.nama,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      alamat: alamat ?? this.alamat,
      email: email ?? this.email,
      role: role ?? this.role,
      agama: agama ?? this.agama,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      noKtp: noKtp ?? this.noKtp,
      suku: suku ?? this.suku,
      namaAyah: namaAyah ?? this.namaAyah,
      namaIbu: namaIbu ?? this.namaIbu,
    );
  }
}