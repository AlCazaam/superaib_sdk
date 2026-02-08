library superaib_sdk;

import 'package:dio/dio.dart';
import 'package:superaib_sdk/src/auth_module.dart';
import 'package:superaib_sdk/src/database_module.dart';
import 'package:superaib_sdk/src/realtime_module.dart';

// 🚀 EXPORTS: Si App-kaagu u arko dhamaan Classes-ka muhiimka ah
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

  // Modules-ka SDK-ga
  late final SuperAIBAuth auth;
  late final SuperAIBDatabase db;
  late final SuperAIBRealtime realtime;

  // Constructor-ka gaarka ah (Private)
  SuperAIB._internal({
    required this.projectRef,
    required this.apiKey,
    required this.baseUrl,
  }) {
    // 🛠️ 1. SETUP DIO: Kani waa mishiinka xogta qaada
    _client = Dio(BaseOptions(
      baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
      headers: {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      },
    ));

    // 🛠️ 2. INITIALIZE MODULES
    auth = SuperAIBAuth(_client, projectRef);
    db = SuperAIBDatabase(_client, projectRef);
    
    // 🚀 MUHIIM: Realtime module hadda wuxuu qaataa Dio instance (_client)
    realtime = SuperAIBRealtime(_client, projectRef, apiKey);
  }

  // 🚀 INITIALIZE: Kani waa midka looga waco Main.dart
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
    
    print("🚀 SuperAIB SDK: Initialized successfully in HTTP Realtime mode.");
    return _instance!;
  }

  // Identity Management (User Tracking)
  void setIdentity(String userID) {
    print("🆔 SDK: User identity set to [$userID]");
  }

  void clearIdentity() {
    print("🆔 SDK: Identity cleared.");
    realtime.disconnect(); // Jooji dhamaan polling-ka socda
  }

  // Singleton Instance Getter
  static SuperAIB get instance {
    if (_instance == null) {
      throw Exception("❌ SuperAIB SDK: Not initialized! Call SuperAIB.initialize() first.");
    }
    return _instance!;
  }
}