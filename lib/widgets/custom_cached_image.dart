// lib/widgets/custom_cached_image.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomCachedImage extends StatefulWidget {
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

  @override
  State<CustomCachedImage> createState() => _CustomCachedImageState();
}

class _CustomCachedImageState extends State<CustomCachedImage> {
  File? _localFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initImage();
  }

  @override
  void didUpdateWidget(CustomCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _initImage();
    }
  }

  Future<void> _initImage() async {
    if (widget.imageUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    try {
      // Menggunakan base64UrlEncode untuk nama file unik dari URL
      final hash = base64UrlEncode(utf8.encode(widget.imageUrl));
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$hash');

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _localFile = file;
            _isLoading = false;
          });
        }
        return;
      }

      // Download file gambar
      final response = await http.get(Uri.parse(widget.imageUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          setState(() {
            _localFile = file;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Status code ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("CustomCachedImage download error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? Container(
        width: widget.width,
        height: widget.height,
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

    if (_hasError || _localFile == null) {
      return widget.errorWidget ?? Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFFf1f5f9),
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: Color(0xFF94a3b8)),
        ),
      );
    }

    return Image.file(
      _localFile!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ?? Container(
          width: widget.width,
          height: widget.height,
          color: const Color(0xFFf1f5f9),
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Color(0xFF94a3b8)),
          ),
        );
      },
    );
  }
}
