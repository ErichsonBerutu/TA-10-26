// lib/widgets/cached_image_native.dart
//
// Implementasi cache gambar untuk platform native (Android, iOS, Desktop).
// Menggunakan file sistem lokal (dart:io) untuk menyimpan gambar yang sudah diunduh.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Membangun widget gambar dengan cache lokal untuk platform native.
Widget buildCachedImage({
  required String imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  return _NativeCachedImage(
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
    placeholder: placeholder,
    errorWidget: errorWidget,
  );
}

class _NativeCachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const _NativeCachedImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<_NativeCachedImage> createState() => _NativeCachedImageState();
}

class _NativeCachedImageState extends State<_NativeCachedImage> {
  File? _localFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initImage();
  }

  @override
  void didUpdateWidget(_NativeCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _initImage();
    }
  }

  Future<void> _initImage() async {
    if (widget.imageUrl.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
      return;
    }

    try {
      final hash = base64UrlEncode(utf8.encode(widget.imageUrl));
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$hash');

      if (await file.exists()) {
        if (mounted) setState(() { _localFile = file; _isLoading = false; });
        return;
      }

      final response = await http.get(Uri.parse(widget.imageUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) setState(() { _localFile = file; _isLoading = false; });
      } else {
        throw Exception('Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('NativeCachedImage error (${widget.imageUrl}): $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return widget.placeholder ?? const SizedBox.shrink();
    if (_hasError || _localFile == null) return widget.errorWidget ?? const SizedBox.shrink();
    return Image.file(
      _localFile!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => widget.errorWidget ?? const SizedBox.shrink(),
    );
  }
}
