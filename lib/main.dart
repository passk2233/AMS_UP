
import 'package:flutter/material.dart';
import 'package:frontend/app/modules/student/student_home/bindings/home_student_binding.dart';
import 'package:frontend/app/routes/app_pages.dart';
import 'package:frontend/app/widgets/app_colors.dart';
import 'package:frontend/app/widgets/app_typography.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/firebase_options.dart';
import 'package:frontend/app/services/auth_storage.dart';
import 'package:frontend/app/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FCMService.init();

  final initialRoute = await _resolveInitialRoute();

  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> _resolveInitialRoute() async {
  final token = await AuthStorage.readToken();
  if (token == null || token.isEmpty) return Routes.AUTH;

  final prefs = await SharedPreferences.getInstance();
  final rememberUntil = prefs.getInt('remember_until');
  if (rememberUntil == null ||
      rememberUntil < DateTime.now().millisecondsSinceEpoch) {
    // Treat stale remember window as a forced re-login; clear the token so
    // the user lands on /auth with no auto-login resume.
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

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: AppTypography.toMaterialTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.heading,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryFill,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(64, AppColors.minTouchTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(64, AppColors.minTouchTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
          ),
        ),
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(HomeStudentBinding());
      }),
    );
  }
}
