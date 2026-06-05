<?php
/**
 * Script untuk membersihkan data jenis_surat yang ter-soft-delete
 * tapi masih ada di database.
 *
 * Jalankan dari root folder Sistem-Administrasi-Desa:
 *   php artisan tinker < cleanup_soft_deleted_jenis_surat.php
 *
 * ATAU copy-paste ke php artisan tinker:
 */

// Tampilkan data yang akan dihapus
$softDeleted = DB::table('jenis_surat')->whereNotNull('deleted_at')->get();

echo "=== Data Jenis Surat yang Ter-Soft-Delete ===\n";
foreach ($softDeleted as $item) {
    echo "ID: {$item->id_jenis_surat} | Nama: {$item->nama_surat} | Deleted: {$item->deleted_at}\n";
}

if ($softDeleted->isEmpty()) {
    echo "Tidak ada data soft-deleted. Database sudah bersih.\n";
} else {
    echo "\nTotal: " . $softDeleted->count() . " record akan dihapus permanen.\n";

    // Hapus persyaratan surat yang terkait
    $ids = $softDeleted->pluck('id_jenis_surat');
    DB::table('persyaratan_surat')->whereIn('jenis_surat_id', $ids)->delete();
    echo "Persyaratan surat terkait dihapus.\n";

    // Hapus permanen record soft-deleted
    DB::table('jenis_surat')->whereNotNull('deleted_at')->delete();
    echo "Jenis surat soft-deleted dihapus permanen dari database.\n";
    echo "SELESAI. Sekarang Anda bisa membuat jenis surat dengan nama yang sama.\n";
}
