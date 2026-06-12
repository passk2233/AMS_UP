import 'package:flutter/material.dart';
import 'package:frontend/app/routes/app_pages.dart';
import 'package:frontend/app/widgets/app_colors.dart';
import 'package:frontend/app/widgets/app_typography.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/firebase_options.dart';
import 'package:frontend/app/services/fcm_service.dart';

/// Background / terminated isolate entry point.
///
/// We do **not** post a notification here: the backend always sends a
/// `notification` payload, so Android/iOS build and show the system
/// notification automatically (using the channel + icon declared in
/// `AndroidManifest.xml`) before this Dart handler even runs. This handler
/// exists only to let us do optional background data work; taps are routed by
/// `FCMService` via `onMessageOpenedApp` / `getInitialMessage`.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // isOptional: a missing/empty .env (fresh clone — copy .env.example) must
  // not crash boot; the splash screen's backend-reachability check is what
  // surfaces an unset API_URL to the user.
  await dotenv.load(fileName: ".env", isOptional: true);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FCMService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // The splash is the boot gate: it verifies the backend is reachable,
      // then resolves the role-aware landing route (token + remember window +
      // role) that used to be computed here before `runApp`.
      initialRoute: Routes.SPLASH,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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
      builder: (context, child) {
        // Clamp dynamic type: very large system font scales otherwise overflow
        // the dense fixed-height rows (48dp chips, stat tiles, 10–13px meta).
        // User scaling is still honored up to a legible 1.3× ceiling.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
