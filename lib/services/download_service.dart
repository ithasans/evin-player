import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    },
  ));

  Future<String> getMusicStorageDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${docsDir.path}/offline_music');
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir.path;
  }

  Future<String> downloadSong(
    String url,
    String filename, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dirPath = await getMusicStorageDirectory();
    final cleanName = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final filePath = '$dirPath/$cleanName';

    final targetFile = File(filePath);
    if (await targetFile.exists() && await targetFile.length() > 50000) {
      return filePath;
    }

    await _dio.download(
      url,
      filePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    return filePath;
  }

  Future<bool> deleteSongFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<double> calculateOfflineStorageMB() async {
    try {
      final dirPath = await getMusicStorageDirectory();
      final dir = Directory(dirPath);
      if (!await dir.exists()) return 0.0;

      int totalBytes = 0;
      await for (final file in dir.list(recursive: false)) {
        if (file is File) {
          totalBytes += await file.length();
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> clearAllOfflineStorage() async {
    try {
      final dirPath = await getMusicStorageDirectory();
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
