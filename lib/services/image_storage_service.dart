import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageStorageService {
  static const String _dogImagesFolder = 'dog_images';

  /// Get the directory where dog images are stored
  static Future<Directory> _getDogImagesDirectory() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final dogImagesDir = Directory(path.join(appDocumentsDir.path, _dogImagesFolder));
    
    // Create directory if it doesn't exist
    if (!await dogImagesDir.exists()) {
      await dogImagesDir.create(recursive: true);
    }
    
    return dogImagesDir;
  }

  /// Save an image file to permanent storage and return the new path
  static Future<String> saveImageToPermanentStorage(File imageFile, String dogId) async {
    try {
      final dogImagesDir = await _getDogImagesDirectory();
      
      // Generate a unique filename for this dog
      final extension = path.extension(imageFile.path);
      final fileName = '${dogId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final permanentPath = path.join(dogImagesDir.path, fileName);
      
      // Copy the image to permanent storage
      final permanentFile = await imageFile.copy(permanentPath);
      
      return permanentFile.path;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  /// Save image bytes to permanent storage and return the path
  static Future<String> saveImageBytesToPermanentStorage(Uint8List imageBytes, String dogId, String extension) async {
    try {
      final dogImagesDir = await _getDogImagesDirectory();
      
      // Generate a unique filename for this dog
      final fileName = '${dogId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final permanentPath = path.join(dogImagesDir.path, fileName);
      
      // Write bytes to file
      final permanentFile = File(permanentPath);
      await permanentFile.writeAsBytes(imageBytes);
      
      return permanentFile.path;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  /// Delete an image file from permanent storage
  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  /// Check if an image file exists
  static Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get all stored dog images
  static Future<List<File>> getAllDogImages() async {
    try {
      final dogImagesDir = await _getDogImagesDirectory();
      final files = await dogImagesDir.list().toList();
      
      return files
          .where((entity) => entity is File)
          .cast<File>()
          .where((file) => _isImageFile(file.path))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if a file is an image based on extension
  static bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  /// Clean up old temporary images (older than 24 hours)
  static Future<void> cleanupOldImages() async {
    try {
      final dogImagesDir = await _getDogImagesDirectory();
      final files = await dogImagesDir.list().toList();
      final now = DateTime.now();
      
      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          
          // Delete files older than 30 days to prevent storage buildup
          if (age.inDays > 30) {
            try {
              await entity.delete();
            } catch (e) {
              print('Error deleting old image: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
}
