import 'dart:io';
import 'package:flutter/material.dart';

class SmartImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildFallback();
    }

    if (imagePath!.startsWith('http://') || imagePath!.startsWith('https://')) {
      // Network image
      return Image.network(
        imagePath!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildLoadingIndicator(loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildFallback();
        },
      );
    } else {
      // Local file - handle both absolute paths and file:// URIs
      String filePath = imagePath!;
      if (filePath.startsWith('file://')) {
        filePath = filePath.substring(7); // Remove 'file://' prefix
      }
      
      return Image.file(
        File(filePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildFallback();
        },
      );
    }
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.pets,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }
}

class SmartCircleAvatar extends StatelessWidget {
  final String? imagePath;
  final double radius;
  final Widget? fallbackWidget;

  const SmartCircleAvatar({
    super.key,
    required this.imagePath,
    this.radius = 20,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: fallbackWidget ?? Icon(Icons.pets, size: radius, color: Colors.grey),
      );
    }

    if (imagePath!.startsWith('http://') || imagePath!.startsWith('https://')) {
      // Network image
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imagePath!),
        onBackgroundImageError: (exception, stackTrace) {
          // This will show the fallback
        },
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.network(
              imagePath!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: radius * 2,
                  height: radius * 2,
                  color: Colors.grey[300],
                  child: fallbackWidget ?? Icon(Icons.pets, size: radius, color: Colors.grey),
                );
              },
            ),
          ),
        ),
      );
    } else {
      // Local file - handle both absolute paths and file:// URIs
      String filePath = imagePath!;
      if (filePath.startsWith('file://')) {
        filePath = filePath.substring(7); // Remove 'file://' prefix
      }
      
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(filePath)),
        onBackgroundImageError: (exception, stackTrace) {
          // This will show the fallback
        },
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.file(
              File(filePath),
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: radius * 2,
                  height: radius * 2,
                  color: Colors.grey[300],
                  child: fallbackWidget ?? Icon(Icons.pets, size: radius, color: Colors.grey),
                );
              },
            ),
          ),
        ),
      );
    }
  }
}
