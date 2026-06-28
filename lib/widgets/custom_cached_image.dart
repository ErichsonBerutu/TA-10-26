// lib/widgets/custom_cached_image.dart
//
// Widget gambar universal yang bekerja di Flutter Web maupun native (Android/iOS).
// - Web: menggunakan Image.network() karena dart:io tidak tersedia di browser
// - Native: menggunakan cache file lokal manual untuk efisiensi bandwidth

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Import dart:io hanya jika bukan Web
import 'cached_image_native.dart'
    if (dart.library.html) 'cached_image_web.dart' as ImageHelper;

class CustomCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CustomCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFf1f5f9),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
        ),
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFf1f5f9),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Color(0xFF94a3b8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _defaultError();

    if (kIsWeb) {
      // Flutter Web: gunakan Image.network langsung
      // Browser menangani caching secara otomatis
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _defaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('CustomCachedImage web error ($imageUrl): $error');
          return errorWidget ?? _defaultError();
        },
      );
    }

    // Native (Android/iOS/Desktop): gunakan implementasi dengan file cache
    return ImageHelper.buildCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder ?? _defaultPlaceholder(),
      errorWidget: errorWidget ?? _defaultError(),
    );
  }
}
