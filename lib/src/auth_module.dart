import 'package:dio/dio.dart';

class SuperAIBAuth {
  final Dio _dio;
  final String _projectRef;
  String? _sessionToken;

  SuperAIBAuth(this._dio, this._projectRef);

  // 1️⃣ REGISTER USER (Email/Password)
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final res = await _dio.post(
        '/projects/$_projectRef/auth-users',
        data: {
          'email': email,
          'password': password,
          'metadata': metadata ?? {},
        },
      );
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 2️⃣ LOGIN USER (Standard)
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/projects/$_projectRef/auth-users/login',
        data: {'email': email, 'password': password},
      );
      _saveSession(res.data['data']['access_token']);
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 3️⃣ GOOGLE LOGIN
  Future<Map<String, dynamic>> signInWithGoogle(String idToken) async {
    try {
      final res = await _dio.post(
        '/projects/$_projectRef/auth-users/google',
        data: {'idToken': idToken},
      );
      _saveSession(res.data['data']['access_token']);
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 4️⃣ FACEBOOK LOGIN
  Future<Map<String, dynamic>> signInWithFacebook(String accessToken) async {
    try {
      final res = await _dio.post(
        '/projects/$_projectRef/auth-users/facebook',
        data: {'accessToken': accessToken},
      );
      _saveSession(res.data['data']['access_token']);
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 5️⃣ FORGOT PASSWORD (SEND OTP)
  // Backend wuxuu u baahan yahay Endpoint: /projects/{ref}/auth-users/forgot-password
  Future<void> sendPasswordResetOtp(String email) async {
    try {
      await _dio.post(
        '/projects/$_projectRef/auth-users/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 6️⃣ VERIFY OTP & RESET PASSWORD
  // Backend wuxuu u baahan yahay Endpoint: /projects/{ref}/auth-users/reset-password
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/projects/$_projectRef/auth-users/reset-password',
        data: {'email': email, 'otp': otp, 'password': newPassword},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 7️⃣ IMPERSONATION LOGIN (Developer Superpower)
  // Backend wuxuu u baahan yahay Endpoint: /projects/{ref}/auth-users/impersonate
  Future<Map<String, dynamic>> signInWithImpersonationToken(
    String token,
  ) async {
    try {
      final res = await _dio.post(
        '/projects/$_projectRef/auth-users/impersonate',
        data: {'token': token},
      );
      _saveSession(res.data['data']['access_token']);
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 8️⃣ LOGOUT
  Future<void> signOut() async {
    _sessionToken = null;
    _dio.options.headers.remove('Authorization');
  }

  // Helper: Save Session
  void _saveSession(String token) {
    _sessionToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Helper: Error Handling
  Exception _handleError(DioException e) {
    final message =
        e.response?.data['message'] ?? "An unexpected error occurred";
    return Exception(message);
  }
}
