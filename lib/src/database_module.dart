import 'package:dio/dio.dart';
import 'query_builder.dart';

class SuperAIBDatabase {
  final Dio _dio;
  final String _projectRef;

  SuperAIBDatabase(this._dio, this._projectRef);

  // 1. Entry Point: .collection('users')
  SuperAIBCollection collection(String name) {
    return SuperAIBCollection(_dio, _projectRef, name);
  }
}

class SuperAIBCollection extends SuperAIBQuery {
  final Dio _dio;
  final String _projectRef;
  final String _name;

  SuperAIBCollection(this._dio, this._projectRef, this._name) 
      : super(_dio, _projectRef, _name);

  // 2. Point to Document: .doc('user_123')
  SuperAIBDocument doc(String id) {
    return SuperAIBDocument(_dio, _projectRef, _name, id);
  }

  // 3. Add Document: .add({...})
  Future<Map<String, dynamic>> add(Map<String, dynamic> data) async {
    final res = await _dio.post('/projects/$_projectRef/db/$_name', data: data);
    return res.data['data'];
  }
}

class SuperAIBDocument {
  final Dio _dio;
  final String _projectRef;
  final String _collection;
  final String _id;

  SuperAIBDocument(this._dio, this._projectRef, this._collection, this._id);

  // 4. Get Single Doc
  Future<Map<String, dynamic>> get() async {
    final res = await _dio.get('/projects/$_projectRef/db/$_collection/$_id');
    return res.data['data'];
  }

  // 5. Set (Overwrite or Merge)
  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {
    await _dio.put(
      '/projects/$_projectRef/db/$_collection/$_id', 
      queryParameters: {'merge': merge},
      data: data
    );
  }

  // 6. Update (Partial Update)
  Future<void> update(Map<String, dynamic> data) async {
    await _dio.patch('/projects/$_projectRef/db/$_collection/$_id', data: data);
  }

  // 7. Upsert (Update or Create)
  Future<void> upsert(Map<String, dynamic> data) async {
    await _dio.post('/projects/$_projectRef/db/$_collection/$_id/upsert', data: data);
  }

  // 8. Delete
  Future<void> delete() async {
    await _dio.delete('/projects/$_projectRef/db/$_collection/$_id');
  }

  // 9. Exists: .doc(id).exists()
  Future<bool> exists() async {
    final res = await _dio.get('/projects/$_projectRef/db/$_collection/$_id/exists');
    return res.data['data']['exists'];
  }

  // 10. Atomic Increment: .doc(id).increment('likes', 1)
  Future<void> increment(String field, double amount) async {
    await _dio.post('/projects/$_projectRef/db/$_collection/$_id/increment', data: {
      'field': field,
      'amount': amount,
    });
  }
}