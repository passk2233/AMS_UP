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
/// - Silent session refresh on `401 Unauthorized`: the expired access JWT
///   is exchanged via `POST /auth/refresh` (single-flight across concurrent
///   401s) and the original request is retried once. Only when refresh
///   fails — no refresh token stored, revoked, or expired — does the app
///   log out and redirect to `/auth`.
///
/// Use [ApiClient.dio] everywhere instead of constructing `Dio()`
/// directly so auth handling, 401 recovery, and timeouts stay consistent.
class ApiClient {
  ApiClient._();

  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _redirectGuardCooldown = Duration(seconds: 2);

  /// Marker on retried requests so a second 401 (token valid but still
  /// rejected) logs out instead of looping refresh → retry forever.
  static const _kAuthRetried = 'auth_retried';

  static Dio? _instance;
  static bool _redirecting = false;

  /// In-flight refresh, shared so a burst of concurrent 401s (every
  /// controller reloads after an expiry) performs exactly one
  /// `/auth/refresh` round-trip. Dart's event loop makes the `??=`
  /// check-and-set atomic — no lock needed.
  static Future<bool>? _refreshFuture;

  /// Lazily-built shared instance. Configure once via the bootstrap and
  /// then reuse across controllers and services.
  static Dio get dio => _instance ??= _build();

  /// For tests / hot reload — drop the cached instance so the next call to
  /// [dio] rebuilds from current environment values.
  @visibleForTesting
  static void reset() {
    _instance = null;
    _refreshFuture = null;
    _redirecting = false;
  }

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
        onError: _maybeRefreshOn401,
      ),
    );
    return d;
  }

  /// Add `Authorization: Bearer <jwt>` to every outbound request except the
  /// public auth endpoints — login has no token yet, refresh authenticates
  /// with the refresh token in its body, and a stale access token from a
  /// prior session must not leak into either.
  static Future<void> _attachAuthHeader(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuthPath(options.path)) {
      final token = await AuthStorage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  static bool _isPublicAuthPath(String path) =>
      path.contains('/auth/login') || path.contains('/auth/refresh');

  /// Pass through every error, but intercept 401 to refresh the session and
  /// retry the original request once. A 401 from the public auth endpoints
  /// (wrong password, dead refresh token) is the caller's to handle.
  static Future<void> _maybeRefreshOn401(
    DioException e,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = e.response?.statusCode == 401;
    if (!is401 || _isPublicAuthPath(e.requestOptions.path)) {
      handler.next(e);
      return;
    }

    // Second 401 on an already-refreshed-and-retried request: the session
    // is genuinely unusable, stop here.
    if (e.requestOptions.extra[_kAuthRetried] == true) {
      await _handleUnauthorized();
      handler.next(e);
      return;
    }

    final refreshed = await (_refreshFuture ??=
        _refreshSession().whenComplete(() => _refreshFuture = null));
    if (!refreshed) {
      await _handleUnauthorized();
      handler.next(e);
      return;
    }

    try {
      e.requestOptions.extra[_kAuthRetried] = true;
      // The request interceptor re-reads the (new) token from storage and
      // overwrites the stale Authorization header on this retry.
      final response = await dio.fetch<dynamic>(e.requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      // Body not replayable (e.g. a consumed multipart stream) — surface
      // the original 401 so the caller's error handling still runs.
      handler.next(e);
    }
  }

  /// POST `/auth/refresh` with the stored refresh token and persist the
  /// rotated pair. Returns `false` when no token is stored or the backend
  /// rejects it. Uses a throwaway [Dio] so this never recurses through the
  /// shared instance's own interceptors.
  static Future<bool> _refreshSession() async {
    final refreshToken = await AuthStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final bare = Dio(
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
    try {
      final resp = await bare.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = resp.data;
      if (data is! Map<String, dynamic>) return false;

      final token = data['token'];
      if (token is! String || token.isEmpty) return false;
      await AuthStorage.writeToken(token);

      // The backend rotates the refresh token on every use; the old one is
      // already revoked server-side, so persist the replacement immediately.
      final rotated = data['refresh_token'];
      if (rotated is String && rotated.isNotEmpty) {
        await AuthStorage.writeRefreshToken(rotated);
      }

      // Roles ride along in the refresh response — keep the cached copy in
      // sync so role-gated navigation reflects server-side changes.
      final user = data['user'];
      if (user is Map<String, dynamic> && user['roles'] is List) {
        await AuthStorage.writeRoles(
          (user['roles'] as List).map((r) => r.toString()).toList(),
        );
      }
      return true;
    } on DioException catch (e) {
      debugPrint('ApiClient: session refresh failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('ApiClient: session refresh failed: $e');
      return false;
    } finally {
      bare.close(force: true);
    }
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
