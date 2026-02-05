library superaib_sdk;

import 'package:dio/dio.dart';
import 'package:superaib_sdk/src/auth_module.dart';


/// SuperAIB Cloud SDK for Flutter
/// Kani waa mashiinka isku xiraya Mobile App-ka iyo SuperAIB Server.
class SuperAIB {
  static SuperAIB? _instance;

  final String projectRef; // Reference ID-ga Dashboard-ka laga soo qaatay
  final String apiKey;
  final String baseUrl;
  late final Dio _client;

  // Modules: Adeegyada ay SuperAIB bixiso
  late final SuperAIBAuth auth;


  // Private Constructor
  SuperAIB._internal({
    required this.projectRef,
    required this.apiKey,
    required this.baseUrl,
  }) {
    // 1. Setup HTTP Client (Dio)
    _client = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      },
    ));

    // 2. Initialize Modules
    auth = SuperAIBAuth(_client, projectRef);

  }

  /// Initialize SuperAIB SDK
  /// [projectRef] - Reference ID-ga mashruucaaga
  /// [apiKey] - API Key-ga qarsoodiga ah ee mashruucaaga
  /// [baseUrl] - URL-ka server-ka SuperAIB (Default: http://localhost:8080/api/v1)
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
    
    print("🚀 SuperAIB SDK: Initialized successfully for Project [$projectRef]");
    return _instance!;
  }

  /// Get the current instance of SuperAIB
  static SuperAIB get instance {
    if (_instance == null) {
      throw Exception(
        "SuperAIB has not been initialized. Please call SuperAIB.initialize() in your main() function.",
      );
    }
    return _instance!;
  }
}