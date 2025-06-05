// lib/features/profile/presentation/widgets/cached_network_image.dart

import 'package:flutter/material.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class CachedProfileImage extends StatefulWidget {
  final String? imageUrl;
  final double size;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedProfileImage({
    Key? key,
    required this.imageUrl,
    required this.size,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<CachedProfileImage> createState() => _CachedProfileImageState();
}

class _CachedProfileImageState extends State<CachedProfileImage> {
  late ImageProvider? _imageProvider;
  bool _hasError = false;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _updateImageProvider();
  }

  @override
  void didUpdateWidget(CachedProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _updateImageProvider();
    }
  }

  void _updateImageProvider() {
    if (widget.imageUrl != null &&
        widget.imageUrl!.isNotEmpty &&
        widget.imageUrl != _currentUrl) {
      // Clear error state when URL changes
      _hasError = false;
      _currentUrl = widget.imageUrl;
      _imageProvider = NetworkImage(widget.imageUrl!);

      // Preload the image to catch errors early
      _preloadImage();
    } else if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      _imageProvider = null;
      _currentUrl = null;
    }
  }

  Future<void> _preloadImage() async {
    if (_imageProvider != null) {
      try {
        await precacheImage(_imageProvider!, context);
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _imageProvider == null) {
      return widget.errorWidget ?? _buildDefaultAvatar();
    }

    return Image(
      image: _imageProvider!,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return widget.placeholder ?? _buildLoadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });
        return widget.errorWidget ?? _buildDefaultAvatar();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ?? _buildLoadingPlaceholder();
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: AppColors.backgroundDark,
      child: Center(
        child: SizedBox(
          width: widget.size * 0.3,
          height: widget.size * 0.3,
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: AppColors.backgroundDark,
      child: Icon(
        Icons.person,
        size: widget.size * 0.4,
        color: AppColors.textMedium,
      ),
    );
  }
}
