import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/colors.dart';
import 'navigator_key.dart';
import 'screens/splash_screen.dart';
import 'services/bildirim_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ekranı dikey kilitle
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar tamamen şeffaf - header rengi geçsin
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Bildirim servisini başlat (Firebase.initializeApp burada çağrılıyor)
  await BildirimService.initialize();

  runApp(const SmkSonucApp());
}

class SmkSonucApp extends StatelessWidget {
  const SmkSonucApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4338CA),
      surface: const Color(0xFFF4F6FB),
    ).copyWith(
      surfaceTint: Colors.transparent,
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SMK Sonuç',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF4338CA),
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        colorScheme: colorScheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        cardTheme: const CardThemeData(
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            surfaceTintColor: Colors.transparent,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            surfaceTintColor: Colors.transparent,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            surfaceTintColor: Colors.transparent,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          modalBackgroundColor: Colors.transparent,
        ),
        dialogTheme: const DialogThemeData(
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          surfaceTintColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.white,
        ),
      ),
      home: const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: SplashScreen(),
      ),
    );
  }
}