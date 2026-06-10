import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keychain/Keystore-backed storage for the auth JWT and role list.
///
/// The first version of the app stored both in [SharedPreferences], which is
/// plain XML in the Android app sandbox and `NSUserDefaults` on iOS —
/// readable on rooted / jailbroken devices. [FlutterSecureStorage] wraps the
/// OS Keychain (iOS) / `EncryptedSharedPreferences` (Android) instead.
///
/// On first read after an upgrade, the legacy values are migrated across
/// once and then cleared from [SharedPreferences] so the plain-text copy
/// goes away.
class AuthStorage {
  AuthStorage._();

  static const _kToken = 'token';
  static const _kRefreshToken = 'refresh_token';
  static const _kRoles = 'roles';
  static const _kRememberUntil = 'remember_until';
  static const _kRolesSeparator = '|';

  static final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Read the JWT, migrating from legacy [SharedPreferences] if necessary.
  /// Returns `null` when no token is stored.
  static Future<String?> readToken() async {
    final v = await _secure.read(key: _kToken);
    if (v != null && v.isNotEmpty) return v;
    return _migrateTokenFromPrefs();
  }

  /// Persist [token] to secure storage and remove any legacy plain copy.
  static Future<void> writeToken(String token) async {
    await _secure.write(key: _kToken, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
  }

  /// Read the stored refresh token. Returns `null` when none is stored —
  /// e.g. a session started against a backend that predates `/auth/refresh`.
  /// No legacy migration: the key never existed in [SharedPreferences].
  static Future<String?> readRefreshToken() =>
      _secure.read(key: _kRefreshToken);

  /// Persist the (rotated) refresh token. The backend invalidates the
  /// previous one on every `/auth/refresh`, so the stored value is always
  /// the only live token for this device.
  static Future<void> writeRefreshToken(String token) =>
      _secure.write(key: _kRefreshToken, value: token);

  /// Read the persisted roles list, migrating from legacy
  /// [SharedPreferences] if necessary. Returns `const []` when not set.
  static Future<List<String>> readRoles() async {
    final raw = await _secure.read(key: _kRoles);
    if (raw != null && raw.isNotEmpty) {
      return raw.split(_kRolesSeparator).where((s) => s.isNotEmpty).toList();
    }
    return _migrateRolesFromPrefs();
  }

  /// Persist [roles] to secure storage and remove any legacy plain copy.
  static Future<void> writeRoles(List<String> roles) async {
    await _secure.write(key: _kRoles, value: roles.join(_kRolesSeparator));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRoles);
  }

  /// Wipe everything auth-related (token + roles + remember-me prefs).
  ///
  /// Safe to call from a logout flow, but any cleanup that depends on the
  /// JWT (e.g. `FCMService.clearTokenOnLogout`) must run **before** this.
  static Future<void> clear() async {
    await _secure.delete(key: _kToken);
    await _secure.delete(key: _kRefreshToken);
    await _secure.delete(key: _kRoles);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kRoles);
    await prefs.remove(_kRememberUntil);
  }

  static Future<String?> _migrateTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_kToken);
    if (legacy == null || legacy.isEmpty) return null;
    await _secure.write(key: _kToken, value: legacy);
    await prefs.remove(_kToken);
    return legacy;
  }

  static Future<List<String>> _migrateRolesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getStringList(_kRoles) ?? const <String>[];
    if (legacy.isEmpty) return const <String>[];
    await _secure.write(key: _kRoles, value: legacy.join(_kRolesSeparator));
    await prefs.remove(_kRoles);
    return legacy;
  }
}
