import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('onboarded') ?? false;
  runApp(CatchApp(onboarded: onboarded, prefs: prefs));
}

class CatchApp extends StatefulWidget {
  final bool onboarded;
  final SharedPreferences prefs;
  const CatchApp({super.key, required this.onboarded, required this.prefs});

  @override
  State<CatchApp> createState() => _CatchAppState();
}

class _CatchAppState extends State<CatchApp> {
  late bool _onboarded;
  final AppTheme _theme = const AppTheme(accent: kDefaultAccent, dark: true);

  @override
  void initState() {
    super.initState();
    _onboarded = widget.onboarded;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void _finishOnboarding() {
    widget.prefs.setBool('onboarded', true);
    setState(() => _onboarded = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    return MaterialApp(
      title: 'Catch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(primary: t.accent, surface: t.pageBg),
        textTheme: GoogleFonts.hankenGroteskTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: t.pageBg,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: _onboarded
          ? HomeScreen(t: t)
          : OnboardingScreen(t: t, onFinish: _finishOnboarding),
    );
  }
}
