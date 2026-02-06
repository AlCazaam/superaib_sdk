library superaib_sdk;

import 'package:dio/dio.dart';
import 'package:superaib_sdk/src/auth_module.dart';
import 'package:superaib_sdk/src/database_module.dart';
import 'package:superaib_sdk/src/realtime_module.dart';

// 🚀 MUHIIM: Kuwan la'aantood App-ka ma arki karo Classes-ka modules-ka ku jira
export 'package:superaib_sdk/src/auth_module.dart';
export 'package:superaib_sdk/src/database_module.dart';
export 'package:superaib_sdk/src/realtime_module.dart';
export 'package:superaib_sdk/src/realtime_channel.dart';
export 'package:superaib_sdk/src/query_builder.dart';

class SuperAIB {
  static SuperAIB? _instance;

  final String projectRef; 
  final String apiKey;
  final String baseUrl;
  late final Dio _client;

  late final SuperAIBAuth auth;
  late final SuperAIBDatabase db;
  late final SuperAIBRealtime realtime;

  SuperAIB._internal({
    required this.projectRef,
    required this.apiKey,
    required this.baseUrl,
  }) {
    _client = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      },
    ));

    auth = SuperAIBAuth(_client, projectRef);
    db = SuperAIBDatabase(_client, projectRef);
    realtime = SuperAIBRealtime(baseUrl, projectRef, apiKey);
  }

  static SuperAIB initialize({
    required String projectRef,
    required String apiKey,
    String? baseUrl,
  }) {
    _instance = SuperAIB._internal(
      projectRef: projectRef,
      apiKey: apiKey,
      baseUrl: baseUrl ?? "http://localhost:8080/api/v1",
    );
    print("🚀 SuperAIB SDK: Initialized successfully");
    return _instance!;
  }

  void setIdentity(String userID) {
    realtime.setUserID(userID);
  }

  void clearIdentity() {
    realtime.setUserID(null);
    realtime.disconnect();
  }

  static SuperAIB get instance {
    if (_instance == null) throw Exception("SuperAIB not initialized");
    return _instance!;
  }
}