import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_pages.dart';
import '../../../services/auth_storage.dart';

/// High-level state the splash is showing.
enum SplashPhase { connecting, error }

/// Why a connection attempt failed — selects the offline message + icon so the
/// user is told what actually went wrong, not just "cannot connect".
enum SplashFault { offline, timeout, config, unknown }

/// Boot gate for the whole app.
///
/// On launch — and on every retry — it does two things at once:
/// 1. Creeps a perceived-progress bar toward 90% (the view reads
///    [progress] directly), then completes it to 100% on success.
/// 2. Probes whether the backend host is reachable.
///
/// On success it resolves the role-aware landing route and replaces the
/// splash; on a DNS / socket / timeout failure it stops the bar and flips to
/// the offline [SplashPhase.error] state. The route resolution is the exact
/// token + remember-window + role mapping that previously ran inline in
/// `main()` before `runApp`, just moved behind the connectivity gate.
class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  /// Floor on how long the splash stays up. Holds the branded screen for a
  /// deliberate ~3s on launch (and lets the progress bar fill) instead of
  /// flashing past on a fast connection. A slower probe extends the dwell on
  /// its own; this is only the minimum.
  static const int _minVisibleMs = 3000;

  /// How long one reachability probe may run before we call the app offline.
  static const Duration _probeTimeout = Duration(seconds: 6);

  /// Drives the progress fraction (0..1). The value *is* the displayed
  /// fraction: it eases to 0.9 while connecting and finishes to 1.0 on
  /// success, so the view consumes it with no remapping.
  late final AnimationController progress;

  /// Current screen state, watched by the view.
  final Rx<SplashPhase> phase = SplashPhase.connecting.obs;

  /// Why the most recent attempt failed — read by the error view when [phase]
  /// is error to pick the message + icon.
  SplashFault fault = SplashFault.unknown;

  /// Short technical code (a Dio error type or a config note) shown faintly
  /// under the message, so a screenshot tells support what actually broke.
  String? faultDetail;

  /// Set in [onClose] so async work that resolves after disposal is dropped
  /// instead of touching a torn-down controller.
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    _attemptConnect();
  }

  @override
  void onClose() {
    _closed = true;
    progress.dispose();
    super.onClose();
  }

  /// Re-run the whole gate. Wired to the error-state retry button.
  void retry() {
    if (phase.value != SplashPhase.error) return;
    _attemptConnect();
  }

  Future<void> _attemptConnect() async {
    phase.value = SplashPhase.connecting;
    progress
      ..value = 0.0
      ..animateTo(
        0.9,
        duration: const Duration(milliseconds: 6000),
        curve: Curves.easeOutCubic,
      );

    final watch = Stopwatch()..start();
    final fault = await _probe();

    final remaining = _minVisibleMs - watch.elapsedMilliseconds;
    if (remaining > 0) {
      await Future<void>.delayed(Duration(milliseconds: remaining));
    }
    if (_closed) return;

    if (fault != null) {
      this.fault = fault;
      progress.stop();
      phase.value = SplashPhase.error;
      return;
    }

    final route = await _resolveRoute();
    if (_closed) return;
    try {
      await progress.animateTo(
        1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } on TickerCanceled {
      // Controller was disposed mid-animation; the guard below stops us from
      // navigating after teardown.
    }
    if (_closed) return;
    Get.offAllNamed(route);
  }

  /// Probes whether the backend is reachable and, if not, *why*.
  ///
  /// Returns `null` when the host answers with any HTTP status (reachable).
  /// Otherwise it classifies the failure into a [SplashFault] and records a
  /// short [faultDetail] code. Uses a throwaway [Dio] (not the shared
  /// `ApiClient`) so the probe never trips the `401 → /auth` interceptor.
  Future<SplashFault?> _probe() async {
    final base = (dotenv.env['API_URL'] ?? '').trim();
    if (base.isEmpty) {
      faultDetail = 'API_URL not set';
      return SplashFault.config;
    }

    final probe = Dio(
      BaseOptions(
        connectTimeout: _probeTimeout,
        receiveTimeout: _probeTimeout,
        sendTimeout: _probeTimeout,
        headers: const {'ngrok-skip-browser-warning': 'true'},
        validateStatus: (_) => true,
      ),
    );
    try {
      await probe.get<void>(base);
      return null; // any HTTP status means we reached the server
    } on DioException catch (e) {
      if (e.response != null) return null; // got a response → reachable
      faultDetail = e.type.name;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return SplashFault.timeout;
        case DioExceptionType.connectionError:
          return SplashFault.offline;
        default:
          return SplashFault.unknown;
      }
    } catch (e) {
      faultDetail = e.runtimeType.toString();
      return SplashFault.unknown;
    } finally {
      probe.close(force: true);
    }
  }

  /// Role-aware landing route — identical to the resolution that used to run
  /// in `main()`: a missing/empty token or a lapsed remember-window sends the
  /// user to `/auth`, otherwise to the home for their stored role.
  Future<String> _resolveRoute() async {
    final token = await AuthStorage.readToken();
    if (token == null || token.isEmpty) return Routes.AUTH;

    final prefs = await SharedPreferences.getInstance();
    final rememberUntil = prefs.getInt('remember_until');
    if (rememberUntil == null ||
        rememberUntil < DateTime.now().millisecondsSinceEpoch) {
      // Stale remember window → force re-login with no auto-resume.
      await AuthStorage.clear();
      return Routes.AUTH;
    }

    final roles = await AuthStorage.readRoles();
    final lowered = roles.map((r) => r.toLowerCase()).toSet();
    if (lowered.contains('administrator') || lowered.contains('admin')) {
      return Routes.ADMIN_HOME;
    }
    if (lowered.contains('teacher')) return Routes.TEACHER_HOME;
    if (lowered.contains('student')) return Routes.HOME_STUDENT;
    return Routes.AUTH;
  }
}
