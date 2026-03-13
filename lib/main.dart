import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('id'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstRun = prefs.getBool('is_first_run') ?? true;
  
  // Load saved language
  final String languageCode = prefs.getString('language_code') ?? 'id';
  appLocale.value = Locale(languageCode);
  
  runApp(MainApp(isFirstRun: isFirstRun));
}

class MainApp extends StatelessWidget {
  final bool isFirstRun;
  const MainApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'FinTrack',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('id'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4285F4)),
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          home: isFirstRun ? const OnboardingScreen() : const MainScreen(),
        );
      },
    );
  }
}
