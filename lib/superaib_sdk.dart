library superaib_sdk;

import 'package:dio/dio.dart';
import 'package:superaib_sdk/src/auth_module.dart';
import 'package:superaib_sdk/src/database_module.dart';
import 'package:superaib_sdk/src/realtime_module.dart';
import 'package:superaib_sdk/src/storage_module.dart'; // 👈 CUSUB

// 🚀 EXPORTS: Si App-kaagu u arko Classes-ka
export 'package:superaib_sdk/src/auth_module.dart';
export 'package:superaib_sdk/src/database_module.dart';
export 'package:superaib_sdk/src/realtime_module.dart';
export 'package:superaib_sdk/src/realtime_channel.dart';
export 'package:superaib_sdk/src/storage_module.dart'; // 👈 CUSUB
export 'package:superaib_sdk/src/query_builder.dart';

class SuperAIB {
  static SuperAIB? _instance;

  final String projectRef; 
  final String apiKey;
  final String baseUrl;
  late final Dio _client;

  // Modules-ka SDK-ga
  late final SuperAIBAuth auth;
  late final SuperAIBDatabase db;
  late final SuperAIBRealtime realtime;
  late final SuperAIBStorage storage; // 👈 CUSUB

  SuperAIB._internal({
    required this.projectRef,
    required this.apiKey,
    required this.baseUrl,
  }) {
    _client = Dio(BaseOptions(
      baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
      headers: {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      },
    ));

    // Initialize dhamaan modules-ka
    auth = SuperAIBAuth(_client, projectRef);
    db = SuperAIBDatabase(_client, projectRef);
    realtime = SuperAIBRealtime(_client, projectRef, apiKey);
    storage = SuperAIBStorage(_client, projectRef); // 👈 INITIALIZE STORAGE
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
    print("🚀 SuperAIB SDK: Initialized with Auth, DB, Realtime, and Storage.");
    return _instance!;
  }

  // Identity
  void setIdentity(String userID) {
    print("🆔 SDK: Identity set to [$userID]");
  }

  void clearIdentity() {
    realtime.disconnect();
  }

  static SuperAIB get instance {
    if (_instance == null) throw Exception("SuperAIB not initialized");
    return _instance!;
  }
}