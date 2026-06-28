// lib/widgets/cached_image_web.dart
//
// Stub untuk platform Web. Dipilih secara kondisional oleh custom_cached_image.dart
// menggunakan conditional import (dart.library.html).
// Di Web, CustomCachedImage sudah menangani rendering via Image.network langsung
// pada level widget utama, sehingga fungsi ini tidak akan dipanggil.

import 'package:flutter/material.dart';

/// Stub — tidak digunakan di Web karena CustomCachedImage menangani kIsWeb sendiri.
Widget buildCachedImage({
  required String imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  // Fallback: gunakan Image.network langsung
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return placeholder ?? const SizedBox.shrink();
    },
    errorBuilder: (_, __, ___) => errorWidget ?? const SizedBox.shrink(),
  );
}
