import 'package:dio/dio.dart';

/// Filter model oo loo diro Backend-ka
class SuperAIBFilter {
  final String field;
  final String op;
  final dynamic value;
  final bool isOr;

  SuperAIBFilter(this.field, this.op, this.value, {this.isOr = false});

  Map<String, dynamic> toJson() => {
    'field': field,
    'op': op,
    'value': value,
    'is_or': isOr,
  };
}

/// Mashiinka dhisaya Query-ga (Select, Where, Limit, etc.)
class SuperAIBQuery {
  final Dio _dio;
  final String _projectRef;
  final String _collectionName;

  final List<SuperAIBFilter> _filters = [];
  List<String>? _selectFields;
  String? _orderBy;
  int? _limit;
  int? _offset;
  String? _searchQuery;

  SuperAIBQuery(this._dio, this._projectRef, this._collectionName);

  // 1. Where Clause: .where('price', '>', 100)
  SuperAIBQuery where(String field, String op, dynamic value) {
    _filters.add(SuperAIBFilter(field, op, value));
    return this;
  }

  // 2. Or Where: .orWhere('category', '==', 'Electronics')
  SuperAIBQuery orWhere(String field, String op, dynamic value) {
    _filters.add(SuperAIBFilter(field, op, value, isOr: true));
    return this;
  }

  // 3. Select: .select(['name', 'price'])
  SuperAIBQuery select(List<String> fields) {
    _selectFields = fields;
    return this;
  }

  // 4. OrderBy: .orderBy('createdAt', descending: true)
  SuperAIBQuery orderBy(String field, {bool descending = false}) {
    _orderBy = "$field ${descending ? 'DESC' : 'ASC'}";
    return this;
  }

  // 5. Limit
  SuperAIBQuery limit(int n) {
    _limit = n;
    return this;
  }

  // 6. Offset (Pagination)
  SuperAIBQuery offset(int n) {
    _offset = n;
    return this;
  }

  // 7. Full-Text Search: .search('iphone')
  SuperAIBQuery search(String query) {
    _searchQuery = query;
    return this;
  }

  /// EXECUTION: Soo qaado xogta dhabta ah
  Future<List<dynamic>> get() async {
    try {
      final res = await _dio.post(
        '/projects/$_projectRef/db/$_collectionName/query',
        data: {
          'filters': _filters.map((f) => f.toJson()).toList(),
          'select': _selectFields,
          'limit': _limit,
          'offset': _offset,
          'order_by': _orderBy,
          'search': _searchQuery,
        },
      );
      return res.data['data'];
    } catch (e) {
      throw Exception("Query Failed: $e");
    }
  }

  /// COUNT: Tirada xogta iyadoon dhamaan la soo dejin
  Future<int> count() async {
    try {
      final res = await _dio.post(
        '/projects/$_projectRef/db/$_collectionName/count',
        data: _filters.map((f) => f.toJson()).toList(),
      );
      return res.data['data']['count'];
    } catch (e) {
      throw Exception("Count Failed: $e");
    }
  }
}