import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../../../services/auth_storage.dart';
import '../data_exporter.dart';

/// Result of a successful login: the access JWT, the long-lived refresh
/// token, and the signed-in user.
class AuthSession {
  AuthSession({required this.token, this.refreshToken, required this.user});

  final String token;

  /// 30-day single-use refresh token. Nullable for tolerance of a backend
  /// that predates `/auth/refresh` — everything still works, the session
  /// just cannot outlive the access JWT.
  final String? refreshToken;

  final UserModel user;
}

/// Data-access layer for authentication / current-user endpoints.
///
/// Owns the `/auth/*` paths and the JSON → model mapping. Controllers depend
/// on this instead of [ApiClient.dio] so the endpoint shape lives in one
/// place and the sign-in / profile flows are unit-testable with a mock.
///
/// Methods throw [DioException] on a transport / non-2xx failure; the caller
/// owns the user-facing error handling.
class AuthProvider {
  AuthProvider({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// GET `/auth/me` → the signed-in [UserModel], or `null` when the payload
  /// is not a JSON object.
  Future<UserModel?> me() async {
    final response = await _dio.get('/auth/me');
    final data = response.data;
    if (data is Map<String, dynamic>) return UserModel.fromJson(data);
    return null;
  }

  /// POST `/auth/login`. Returns the token + user on success; throws on
  /// failure. The transport skips the auth header for this path, so a stale
  /// token in storage does not leak in.
  Future<AuthSession> login({
    required String username,
    required String password,
    required String platform,
    String? deviceToken,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
        'device_token': deviceToken,
        'platform': platform,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return AuthSession(
      token: data['token'] as String,
      refreshToken: data['refresh_token'] as String?,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// POST `/auth/logout` — revoke the stored refresh token server-side (or
  /// every session of the account when no token is stored locally).
  ///
  /// Best-effort, never throws: local logout must proceed even when the
  /// device is offline or the backend predates the endpoint. The access JWT
  /// is stateless and cannot be revoked; the caller clears it from storage.
  Future<void> logout() async {
    try {
      final refreshToken = await AuthStorage.readRefreshToken();
      await _dio.post(
        '/auth/logout',
        data: (refreshToken == null || refreshToken.isEmpty)
            ? null
            : {'refresh_token': refreshToken},
      );
    } on DioException catch (e) {
      debugPrint('AuthProvider.logout: server revoke failed: ${e.message}');
    } catch (e) {
      debugPrint('AuthProvider.logout: server revoke failed: $e');
    }
  }
}
