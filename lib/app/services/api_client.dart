import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';
import 'auth_storage.dart';

/// Single shared [Dio] instance for the whole app.
///
/// Centralizes:
/// - Base URL + connect / receive timeouts (read once from `.env`).
/// - The `Authorization: Bearer <jwt>` header (read fresh from secure
///   storage on every request, so a token refresh / login from one
///   screen is picked up by every other screen).
/// - Automatic logout + redirect to `/auth` on `401 Unauthorized`.
///
/// Use [ApiClient.dio] everywhere instead of constructing `Dio()`
/// directly so auth handling, 401 recovery, and timeouts stay consistent.
class ApiClient {
  ApiClient._();

  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _redirectGuardCooldown = Duration(seconds: 2);

  static Dio? _instance;
  static bool _redirecting = false;

  /// Lazily-built shared instance. Configure once via the bootstrap and
  /// then reuse across controllers and services.
  static Dio get dio => _instance ??= _build();

  /// For tests / hot reload — drop the cached instance so the next call to
  /// [dio] rebuilds from current environment values.
  @visibleForTesting
  static void reset() => _instance = null;

  static Dio _build() {
    final d = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_URL'] ?? '',
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        headers: const {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: _attachAuthHeader,
        onError: _maybeRedirectOn401,
      ),
    );
    return d;
  }

  /// Add `Authorization: Bearer <jwt>` to every outbound request except
  /// `/auth/login` — that endpoint has no token yet, and a stale token
  /// from a prior session must not leak in.
  static Future<void> _attachAuthHeader(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.path.contains('/auth/login')) {
      final token = await AuthStorage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  /// Pass through every error, but intercept 401 to wipe the session.
  static Future<void> _maybeRedirectOn401(
    DioException e,
    ErrorInterceptorHandler handler,
  ) async {
    if (e.response?.statusCode == 401) await _handleUnauthorized();
    handler.next(e);
  }

  /// Wipe the local session and bounce to `/auth`.
  ///
  /// Guarded so a burst of 401s (every controller fires its load
  /// concurrently after a token expiry) only triggers a single redirect.
  /// The guard lifts after [_redirectGuardCooldown] so a *later* expiry
  /// from a new session can still trigger.
  static Future<void> _handleUnauthorized() async {
    if (_redirecting) return;
    _redirecting = true;
    try {
      await AuthStorage.clear();
      // Defer so we don't try to navigate while a route is mid-build.
      Future.microtask(() {
        try {
          Get.offAllNamed(Routes.AUTH);
        } catch (e) {
          debugPrint('ApiClient: redirect on 401 failed: $e');
        }
      });
    } finally {
      Future.delayed(_redirectGuardCooldown, () => _redirecting = false);
    }
  }
}
