import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppConstants.glassSurfaceColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.modernBorderRadius,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: AppConstants.modernBorderRadius,
            ),
            minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.padding,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            side: BorderSide(
              color: AppConstants.primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppConstants.modernBorderRadius,
            ),
            minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.padding,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: AppConstants.modernBorderRadius,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.paddingSmall,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.glassSurfaceColor,
          border: OutlineInputBorder(
            borderRadius: AppConstants.modernBorderRadius,
            borderSide: const BorderSide(
              color: AppConstants.dividerColor,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppConstants.modernBorderRadius,
            borderSide: const BorderSide(
              color: AppConstants.dividerColor,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppConstants.modernBorderRadius,
            borderSide: const BorderSide(
              color: AppConstants.primaryColor,
              width: 2.0,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: AppConstants.padding,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
          ),
          displaySmall: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
          titleMedium: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
          titleSmall: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          bodyLarge: TextStyle(
            color: AppConstants.textColor,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(
            color: AppConstants.textColor,
            letterSpacing: 0.25,
          ),
          bodySmall: TextStyle(
            color: AppConstants.textSecondaryColor,
          ),
          labelLarge: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.25,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppConstants.dividerColor,
          thickness: 1,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
