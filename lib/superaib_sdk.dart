library superaib_sdk;

import 'package:dio/dio.dart';
import 'package:superaib_sdk/src/auth_module.dart';
import 'package:superaib_sdk/src/database_module.dart';
import 'package:superaib_sdk/src/realtime_module.dart';


/// SuperAIB Cloud SDK for Flutter
/// Kani waa mashiinka isku xiraya Mobile App-ka iyo SuperAIB Server.
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
    _client = Dio(BaseOptions(baseUrl: baseUrl, headers: {'x-api-key': apiKey}));

    auth = SuperAIBAuth(_client, projectRef);
    db = SuperAIBDatabase(_client, projectRef);
    // Realtime wuxuu ku bilaabanayaa UserID-la'aan (Null)
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
    return _instance!;
  }

  /// 🚀 MUCJISADA CUSUB: Aqoonsiga User-ka marka uu Login sameeyo
  void setIdentity(String userID) {
    realtime.setUserID(userID);
    print("👤 SuperAIB Identity set for User: $userID");
  }

  /// Markuu User-ku Logout yiraahdo
  void clearIdentity() {
    realtime.setUserID(null);
    realtime.disconnect();
  }

  static SuperAIB get instance {
    if (_instance == null) throw Exception("SuperAIB not initialized");
    return _instance!;
  }
}