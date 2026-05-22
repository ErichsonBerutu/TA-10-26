class PersyaratanSuratModel {
  final int id;
  final int jenisSuratId;
  final String namaField;
  final String tipeField; // 'text', 'number', 'date', 'file_image'
  final bool isRequired;

  PersyaratanSuratModel({
    required this.id,
    required this.jenisSuratId,
    required this.namaField,
    required this.tipeField,
    required this.isRequired,
  });

  factory PersyaratanSuratModel.fromJson(Map<String, dynamic> json) {
    return PersyaratanSuratModel(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      jenisSuratId: json['jenis_surat_id'] is int
          ? json['jenis_surat_id']
          : (int.tryParse(json['jenis_surat_id']?.toString() ?? '') ?? 0),
      namaField: json['nama_field']?.toString() ?? '',
      tipeField: json['tipe_field']?.toString() ?? 'text',
      isRequired: json['is_required'] == true ||
          json['is_required'] == 1 ||
          json['is_required'] == '1' ||
          json['is_required'].toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jenis_surat_id': jenisSuratId,
      'nama_field': namaField,
      'tipe_field': tipeField,
      'is_required': isRequired ? 1 : 0,
    };
  }
}
