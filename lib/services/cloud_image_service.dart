import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class CloudImageService {
  /// Convert image file to base64 and upload to Firestore
  static Future<String> uploadDogImageToFirestore(File imageFile, String dogId) async {
    try {
      print('Starting dog image upload for dogId: $dogId'); // Debug log
      print('Image file path: ${imageFile.path}'); // Debug log
      
      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      
      // Check file size (Base64 encoding increases size by ~33%, so we need a smaller limit)
      final fileStat = await imageFile.stat();
      print('File size: ${fileStat.size} bytes'); // Debug log
      if (fileStat.size > 1048576) { // 1MB limit - matching profile image behavior
        throw Exception('Image file is too large (${fileStat.size} bytes). Please choose a smaller image (max 1MB).');
      }
      
      // Read image bytes
      print('Reading image bytes...'); // Debug log
      final imageBytes = await imageFile.readAsBytes();
      print('Image bytes read: ${imageBytes.length} bytes'); // Debug log
      
      // Convert to base64
      print('Converting to base64...'); // Debug log
      final base64Image = base64Encode(imageBytes);
      print('Base64 conversion complete: ${base64Image.length} characters'); // Debug log
      
      // Create a data URL
      final imageDataUrl = 'data:image/jpeg;base64,$base64Image';
      
      // Check if data URL is too large for Firestore fields
      if (imageDataUrl.length > 1048000) { // Leave some buffer
        print('Image too large for direct storage, using chunked approach...'); // Debug log
        
        // Store the image data in chunks in a separate collection
        await _storeImageInChunks(dogId, base64Image);
        
        // Return a reference URL instead of the full data URL
        final referenceUrl = 'firestore://dog_images_chunked/$dogId';
        print('Dog image stored in chunks, returning reference: $referenceUrl'); // Debug log
        return referenceUrl;
      } else {
        print('Image small enough for direct storage: ${imageDataUrl.substring(0, 50)}...'); // Debug log
        print('Dog image upload successful!'); // Debug log
        return imageDataUrl;
      }
    } catch (e) {
      print('Error in uploadDogImageToFirestore: $e'); // Debug log
      throw Exception('Failed to upload dog image: $e');
    }
  }

  /// Store large images in chunks in Firestore
  static Future<void> _storeImageInChunks(String dogId, String base64Image) async {
    const chunkSize = 500000; // 500KB chunks
    final chunks = <String>[];
    
    // Split base64 string into chunks
    for (int i = 0; i < base64Image.length; i += chunkSize) {
      final end = (i + chunkSize < base64Image.length) ? i + chunkSize : base64Image.length;
      chunks.add(base64Image.substring(i, end));
    }
    
    // Store metadata and chunks
    await FirebaseFirestore.instance
        .collection('dog_images_chunked')
        .doc(dogId)
        .set({
      'totalChunks': chunks.length,
      'uploadedAt': FieldValue.serverTimestamp(),
      'mimeType': 'image/jpeg',
    });
    
    // Store each chunk
    for (int i = 0; i < chunks.length; i++) {
      await FirebaseFirestore.instance
          .collection('dog_images_chunked')
          .doc(dogId)
          .collection('chunks')
          .doc('chunk_$i')
          .set({
        'data': chunks[i],
        'chunkIndex': i,
      });
    }
  }

  /// Retrieve chunked image data
  static Future<String> getChunkedImageData(String dogId) async {
    try {
      // Get metadata
      final metaDoc = await FirebaseFirestore.instance
          .collection('dog_images_chunked')
          .doc(dogId)
          .get();
      
      if (!metaDoc.exists) {
        throw Exception('Image not found');
      }
      
      final totalChunks = metaDoc.data()!['totalChunks'] as int;
      
      // Get all chunks
      final chunks = <String>[];
      for (int i = 0; i < totalChunks; i++) {
        final chunkDoc = await FirebaseFirestore.instance
            .collection('dog_images_chunked')
            .doc(dogId)
            .collection('chunks')
            .doc('chunk_$i')
            .get();
        
        if (chunkDoc.exists) {
          chunks.add(chunkDoc.data()!['data'] as String);
        }
      }
      
      // Reassemble the base64 string
      final fullBase64 = chunks.join('');
      return 'data:image/jpeg;base64,$fullBase64';
    } catch (e) {
      print('Error retrieving chunked image: $e');
      throw Exception('Failed to retrieve image: $e');
    }
  }

  /// Convert image file to base64 for profile images
  static Future<String> uploadProfileImageToFirestore(File imageFile, String userId) async {
    try {
      print('Starting profile image upload for userId: $userId'); // Debug log
      print('Image file path: ${imageFile.path}'); // Debug log
      
      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      
      // Check file size (Base64 encoding increases size by ~33%, so we need a smaller limit)
      final fileStat = await imageFile.stat();
      print('File size: ${fileStat.size} bytes'); // Debug log
      if (fileStat.size > 700000) { // 700KB limit to account for base64 expansion
        throw Exception('Image file is too large (${fileStat.size} bytes). Please choose a smaller image (max 700KB).');
      }
      
      // Read image bytes
      print('Reading image bytes...'); // Debug log
      final imageBytes = await imageFile.readAsBytes();
      print('Image bytes read: ${imageBytes.length} bytes'); // Debug log
      
      // Convert to base64
      print('Converting to base64...'); // Debug log
      final base64Image = base64Encode(imageBytes);
      print('Base64 conversion complete: ${base64Image.length} characters'); // Debug log
      
      // Check if base64 string is too large for Firestore
      if (base64Image.length > 1000000) { // 1MB limit for base64 string
        throw Exception('Base64 image data is too large (${base64Image.length} characters). Please choose a smaller image.');
      }
      
      // Create a data URL
      final imageDataUrl = 'data:image/jpeg;base64,$base64Image';
      print('Data URL created: ${imageDataUrl.substring(0, 50)}...'); // Debug log
      
      // Skip Firestore storage for large images - just return the data URL
      // The data URL itself contains all the image data needed for display
      print('Skipping Firestore storage due to size - returning data URL directly'); // Debug log
      
      print('Profile image upload successful!'); // Debug log
      return imageDataUrl;
    } catch (e) {
      print('Error in uploadProfileImageToFirestore: $e'); // Debug log
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Delete image from Firestore
  static Future<void> deleteImageFromFirestore(String collection, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .delete();
    } catch (e) {
      print('Error deleting image from Firestore: $e');
    }
  }

  /// Check if a URL is a data URL (base64 image)
  static bool isDataUrl(String url) {
    return url.startsWith('data:image/');
  }

  /// Extract base64 data from data URL
  static String? getBase64FromDataUrl(String dataUrl) {
    if (!isDataUrl(dataUrl)) return null;
    
    final parts = dataUrl.split(',');
    return parts.length > 1 ? parts[1] : null;
  }

  /// Convert base64 to Uint8List for display
  static Uint8List? base64ToBytes(String input) {
    try {
      // If it's a data URL, extract just the base64 part
      String base64String = input;
      if (input.startsWith('data:image/')) {
        final base64Part = getBase64FromDataUrl(input);
        if (base64Part == null) return null;
        base64String = base64Part;
      }
      
      return base64Decode(base64String);
    } catch (e) {
      print('Error converting base64 to bytes: $e');
      return null;
    }
  }
}
