import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DownloadService {
  static const int _chunkSize = 8192; // 8KB chunks for progress tracking

  Future<String> downloadEbook({
    required String downloadUrl,
    required String bookId,
    required String fileName,
    Function(double progress)? onProgress,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory(path.join(appDir.path, 'books'));

      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final fileExtension = path.extension(fileName);
      final localFileName =
          '${bookId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = path.join(booksDir.path, localFileName);
      final file = File(filePath);

      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {'Accept': '*/*', 'User-Agent': 'Pertukekem App'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final totalBytes = bytes.length;

      await file.create();
      final sink = file.openWrite();

      try {
        int bytesWritten = 0;
        for (int i = 0; i < bytes.length; i += _chunkSize) {
          final end =
              (i + _chunkSize < bytes.length) ? i + _chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);

          sink.add(chunk);
          bytesWritten += chunk.length;

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

  Future<bool> isFileDownloaded(String? localFilePath) async {
    if (localFilePath == null || localFilePath.isEmpty) {
      return false;
    }

    final file = File(localFilePath);
    return await file.exists();
  }

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

  Future<Directory> getBooksDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDir.path, 'books'));
  }

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
