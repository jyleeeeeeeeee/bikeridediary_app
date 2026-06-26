import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../storage/token_storage.dart';
import '../network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class AuthenticatedImage extends ConsumerStatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AuthenticatedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  ConsumerState<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends ConsumerState<AuthenticatedImage> {
  Uint8List? _imageBytes;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      final dio = Dio();
      final response = await dio.get<List<int>>(
        widget.imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      if (mounted) {
        setState(() {
          _imageBytes = Uint8List.fromList(response.data!);
          _loading = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error != null || _imageBytes == null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error ?? 'Unknown error', null);
      }
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    return Image.memory(
      _imageBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
