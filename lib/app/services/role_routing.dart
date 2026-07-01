import '../routes/app_pages.dart';

/// Central role → landing-route mapping shared by login, the splash boot
/// gate, and the in-app role switcher.
///
/// A single user may hold several roles (e.g. a teacher who is also a
/// student). Each role has its own home shell; this decides which one to land
/// on and lists the roles the user can switch between. Kept in one place so
/// the priority order and route table can't drift between the three callers.
class RoleRouting {
  RoleRouting._();

  /// Canonical roles ordered by priority (highest first). The first role a
  /// user holds is their default landing role.
  static const List<String> priority = ['admin', 'teacher', 'student'];

  static const Map<String, String> _routes = {
    'admin': Routes.ADMIN_HOME,
    'teacher': Routes.TEACHER_HOME,
    'student': Routes.HOME_STUDENT,
  };

  /// Fold API role aliases onto a canonical key. Unknown roles pass through
  /// lower-cased and simply won't match a route.
  static String canon(String role) {
    final r = role.toLowerCase();
    return r == 'administrator' ? 'admin' : r;
  }

  /// The canonical roles this user holds that map to a home shell, ordered by
  /// [priority]. Drives the switcher's option list.
  static List<String> known(List<String> roles) {
    final have = roles.map(canon).toSet();
    return priority.where(have.contains).toList();
  }

  /// Landing route for a single role, or `null` if it has no home shell.
  static String? routeFor(String role) => _routes[canon(role)];

  /// Where to send the user: their [active] role if they still hold it,
  /// otherwise their highest-priority role. `null` when they hold no known
  /// role.
  static String? landing(List<String> roles, {String? active}) {
    final k = known(roles);
    if (k.isEmpty) return null;
    if (active != null && k.contains(canon(active))) {
      return _routes[canon(active)];
    }
    return _routes[k.first];
  }
}
