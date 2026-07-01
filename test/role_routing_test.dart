import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/routes/app_pages.dart';
import 'package:frontend/app/services/role_routing.dart';

void main() {
  group('RoleRouting.landing', () {
    test('single role → that role home', () {
      expect(RoleRouting.landing(['student']), Routes.HOME_STUDENT);
      expect(RoleRouting.landing(['teacher']), Routes.TEACHER_HOME);
    });

    test('multi-role with no active → highest priority', () {
      expect(
        RoleRouting.landing(['student', 'teacher', 'admin']),
        Routes.ADMIN_HOME,
      );
    });

    test('active role wins when the user still holds it', () {
      expect(
        RoleRouting.landing(['admin', 'student'], active: 'student'),
        Routes.HOME_STUDENT,
      );
    });

    test('stale active role the user no longer holds → highest priority', () {
      expect(
        RoleRouting.landing(['teacher'], active: 'admin'),
        Routes.TEACHER_HOME,
      );
    });

    test('administrator alias maps to admin home', () {
      expect(RoleRouting.landing(['Administrator']), Routes.ADMIN_HOME);
    });

    test('no known role → null', () {
      expect(RoleRouting.landing(['ghost']), isNull);
      expect(RoleRouting.landing([]), isNull);
    });
  });

  test('RoleRouting.known filters + orders by priority', () {
    expect(RoleRouting.known(['student', 'admin']), ['admin', 'student']);
    expect(RoleRouting.known(['ghost', 'teacher']), ['teacher']);
  });
}
