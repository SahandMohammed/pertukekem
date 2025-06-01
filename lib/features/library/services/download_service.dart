import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DownloadService {
  static const int _chunkSize = 8192; // 8KB chunks for progress tracking

  /// Download an ebook file from URL and save to local storage
  Future<String> downloadEbook({
    required String downloadUrl,
    required String bookId,
    required String fileName,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Get the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory(path.join(appDir.path, 'books'));
      
      // Create books directory if it doesn't exist
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      // Create file path with book ID to avoid conflicts
      final fileExtension = path.extension(fileName);
      final localFileName = '${bookId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = path.join(booksDir.path, localFileName);
      final file = File(filePath);

      // Start download
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'Accept': '*/*',
          'User-Agent': 'Pertukekem App',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final totalBytes = bytes.length;
      
      // Write file in chunks to track progress
      await file.create();
      final sink = file.openWrite();
      
      try {
        int bytesWritten = 0;
        for (int i = 0; i < bytes.length; i += _chunkSize) {
          final end = (i + _chunkSize < bytes.length) ? i + _chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);
          
          sink.add(chunk);
          bytesWritten += chunk.length;
          
          // Report progress
          if (onProgress != null) {
            final progress = bytesWritten / totalBytes;
            onProgress(progress);
          }
        }
      } finally {
        await sink.close();
      }

      return filePath;
    } catch (e) {
      debugPrint('Error downloading ebook: $e');
      throw Exception('Failed to download ebook: $e');
    }
  }

  /// Check if a file exists locally
  Future<bool> isFileDownloaded(String? localFilePath) async {
    if (localFilePath == null || localFilePath.isEmpty) {
      return false;
    }
    
    final file = File(localFilePath);
    return await file.exists();
  }

  /// Get file size in MB
  Future<double> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / (1024 * 1024); // Convert to MB
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    return 0.0;
  }

  /// Delete downloaded file
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get all downloaded books directory
  Future<Directory> getBooksDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDir.path, 'books'));
  }

  /// Clear all downloaded books
  Future<void> clearAllDownloads() async {
    try {
      final booksDir = await getBooksDirectory();
      if (await booksDir.exists()) {
        await booksDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing downloads: $e');
      throw Exception('Failed to clear downloads: $e');
    }
  }

  /// Get total storage used by downloaded books
  Future<double> getTotalStorageUsed() async {
    try {
      final booksDir = await getBooksDirectory();
      if (!await booksDir.exists()) {
        return 0.0;
      }

      double totalSize = 0.0;
      await for (final entity in booksDir.list(recursive: true)) {
        if (entity is File) {
          final bytes = await entity.length();
          totalSize += bytes / (1024 * 1024); // Convert to MB
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating storage: $e');
      return 0.0;
    }
  }
}
