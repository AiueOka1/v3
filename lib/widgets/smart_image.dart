import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pawtech/services/cloud_image_service.dart';

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

    // Handle Firestore chunked image references
    if (imagePath!.startsWith('firestore://dog_images_chunked/')) {
      final dogId = imagePath!.substring('firestore://dog_images_chunked/'.length);
      return FutureBuilder<String>(
        future: CloudImageService.getChunkedImageData(dogId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return errorWidget ?? _buildFallback();
          }
          if (snapshot.hasData) {
            final bytes = CloudImageService.base64ToBytes(snapshot.data!);
            if (bytes != null) {
              return Image.memory(
                bytes,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) {
                  return errorWidget ?? _buildFallback();
                },
              );
            }
          }
          return placeholder ?? _buildLoadingPlaceholder();
        },
      );
    }

    // Handle base64 data URLs
    if (imagePath!.startsWith('data:image/')) {
      final base64String = CloudImageService.getBase64FromDataUrl(imagePath!);
      if (base64String != null) {
        final bytes = CloudImageService.base64ToBytes(base64String);
        if (bytes != null) {
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ?? _buildFallback();
            },
          );
        }
      }
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

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadingIndicator(ImageChunkEvent? loadingProgress) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress?.expectedTotalBytes != null
              ? loadingProgress!.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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

    // Handle Firestore chunked image references
    if (imagePath!.startsWith('firestore://dog_images_chunked/')) {
      final dogId = imagePath!.substring('firestore://dog_images_chunked/'.length);
      return FutureBuilder<String>(
        future: CloudImageService.getChunkedImageData(dogId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[300],
              child: fallbackWidget ?? Icon(Icons.pets, size: radius, color: Colors.grey),
            );
          }
          if (snapshot.hasData) {
            final bytes = CloudImageService.base64ToBytes(snapshot.data!);
            if (bytes != null) {
              return CircleAvatar(
                radius: radius,
                backgroundImage: MemoryImage(bytes),
              );
            }
          }
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[200],
            child: const CircularProgressIndicator(),
          );
        },
      );
    }

    if (imagePath!.startsWith('data:image/')) {
      // Base64 data URL
      try {
        final bytes = CloudImageService.base64ToBytes(imagePath!);
        if (bytes != null) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
            onBackgroundImageError: (exception, stackTrace) {
              // This will show the fallback
            },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.memory(
                  bytes,
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
      } catch (e) {
        // Fall through to show placeholder
      }
      
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: fallbackWidget ?? Icon(Icons.pets, size: radius, color: Colors.grey),
      );
    } else if (imagePath!.startsWith('http://') || imagePath!.startsWith('https://')) {
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
