import 'package:dio/dio.dart';

class SuperAIBStorage {
  final Dio _dio;
  final String _projectRef;

  SuperAIBStorage(this._dio, this._projectRef);

  // 1. CREATE FILE RECORD: Waxaad halkan ku diwaangelinaysaa File-ka Metadata-giisa
  Future<Map<String, dynamic>> createFileRecord({
    required String fileName,
    required String fileType,
    required double sizeMB,
    required String url,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final res = await _dio.post(
        '/projects/$_projectRef/storage/files',
        data: {
          'file_name': fileName,
          'file_type': fileType,
          'size_mb': sizeMB,
          'url': url,
          'metadata': metadata ?? {},
        },
      );
      return res.data['data'];
    } catch (e) {
      throw Exception("❌ Storage: Failed to create file record: $e");
    }
  }

  // 2. LIST FILES: Soo saar dhamaan files-ka mashruuca
  Future<List<dynamic>> listFiles({int page = 1, int pageSize = 12}) async {
    try {
      final res = await _dio.get(
        '/projects/$_projectRef/storage/files',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return res.data['data']['files'];
    } catch (e) {
      throw Exception("❌ Storage: Failed to list files: $e");
    }
  }

  // 3. DELETE FILE: Tirtir file gaar ah
  Future<void> deleteFile(String fileId) async {
    try {
      await _dio.delete('/projects/$_projectRef/storage/files/$fileId');
      print("✅ Storage: File deleted successfully.");
    } catch (e) {
      throw Exception("❌ Storage: Failed to delete file: $e");
    }
  }
}