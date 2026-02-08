import 'dart:io';
import 'package:dio/dio.dart';

class SuperAIBStorage {
  final Dio _dio;
  final String _projectRef;

  SuperAIBStorage(this._dio, this._projectRef);

  // 🚀 1. UPLOAD FILE (Binary): Kani waa kan sawirka dhabta ah diraya
  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      String fileName = file.path.split('/').last;

      // 🛠️ Diyaari Multipart Data
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      print("📤 SDK: Uploading $fileName to SuperAIB Server...");

      // U dir Backend-ka (Backend-ka ayaa Cloudinary u sii gudbinaya)
      final res = await _dio.post(
        '/projects/$_projectRef/storage/upload', // 👈 Hubi inuu router-ka ku jiro
        data: formData,
      );

      print("✅ SDK: Upload successful. URL: ${res.data['data']['url']}");
      return res.data['data'];
    } catch (e) {
      throw Exception("❌ Storage Upload Failed: $e");
    }
  }

  // 2. List Files (sidii hore)
  Future<List<dynamic>> listFiles({int page = 1, int pageSize = 12}) async {
    final res = await _dio.get('/projects/$_projectRef/storage/files', 
      queryParameters: {'page': page, 'pageSize': pageSize});
    return res.data['data']['files'];
  }
}