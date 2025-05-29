// lib/services/supabase_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Upload profile image with simple debugging
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      print('🔍 Starting upload process...');

      // Check user authentication
      final user = _client.auth.currentUser;
      print('🔍 Current user: ${user?.id ?? 'Not logged in'}');
      print('🔍 User role: ${user?.role ?? 'No role'}');

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = 'profiles/$fileName.png';

      print('🔍 File path: $filePath');
      print('🔍 Target bucket: yumcart-images'); // Fixed bucket name

      // Check if file exists
      final fileExists = await imageFile.exists();
      print('🔍 Image file exists: $fileExists');

      if (!fileExists) {
        throw Exception('Selected image file does not exist');
      }

      print('🔍 File size: ${await imageFile.length()} bytes');

      // Try to list buckets to test connection
      print('🔍 Testing storage connection...');
      try {
        final buckets = await _client.storage.listBuckets();
        print('🔍 Found ${buckets.length} buckets');
        for (var bucket in buckets) {
          print('🔍 Available bucket: "${bucket.name}" (public: ${bucket.public})');
        }

        // Check if our target bucket exists
        final hasTargetBucket = buckets.any((bucket) => bucket.name == 'yumcart-images');
        print('🔍 yumcart-images bucket found: $hasTargetBucket');

        if (!hasTargetBucket) {
          print('❌ Bucket "yumcart-images" not found!');
          print('❌ Available buckets: ${buckets.map((b) => '"${b.name}"').join(', ')}');
          throw Exception('Bucket yumcart-images not found. Available: ${buckets.map((b) => b.name).join(', ')}');
        }

        print('✅ Target bucket found!');

      } catch (e) {
        print('❌ Storage connection error: $e');
        throw Exception('Cannot connect to storage: $e');
      }

      // Attempt upload
      print('🔍 Uploading file...');
      final storageResponse = await _client.storage
          .from('yumcart-images') // Fixed bucket name
          .upload(filePath, imageFile);

      print('🔍 Upload response: $storageResponse');

      if (storageResponse.isEmpty) {
        throw Exception('Upload failed - empty response from server');
      }

      // Get public URL
      final publicUrl = _client.storage
          .from('yumcart-images') // Fixed bucket name
          .getPublicUrl(filePath);

      print('✅ Upload successful!');
      print('✅ Public URL: $publicUrl');

      return publicUrl;

    } catch (e) {
      print('❌ Upload failed: $e');
      print('❌ Error details: ${e.toString()}');
      rethrow;
    }
  }

  // Upload recipe image (for future use)
  Future<String> uploadRecipeImage(File imageFile) async {
    final fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}';
    final filePath = 'recipes/$fileName.png';

    final storageResponse = await _client.storage
        .from('yumcart-images') // Fixed bucket name
        .upload(filePath, imageFile);

    if (storageResponse.isEmpty) {
      throw Exception('Recipe image upload failed.');
    }

    final publicUrl = _client.storage
        .from('yumcart-images') // Fixed bucket name
        .getPublicUrl(filePath);

    return publicUrl;
  }
}