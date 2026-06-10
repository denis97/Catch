import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/places_repository.dart';
import 'services/reminder_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('onboarded') ?? false;
  await ReminderService.instance.init();
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
  late PlacesRepository _places;
  bool _isDark = true;

  AppTheme get _theme => AppTheme(accent: kDefaultAccent, dark: _isDark);

  @override
  void initState() {
    super.initState();
    _onboarded = widget.onboarded;
    _places = PlacesRepository(widget.prefs);
    _syncStatusBar(_isDark);
  }

  void _syncStatusBar(bool dark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    ));
  }

  void _finishOnboarding() {
    widget.prefs.setBool('onboarded', true);
    setState(() => _onboarded = true);
  }

  void _toggleTheme() {
    setState(() => _isDark = !_isDark);
    _syncStatusBar(!_isDark);
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    return MaterialApp(
      title: 'Catch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: t.dark ? Brightness.dark : Brightness.light,
        colorScheme: (t.dark ? ColorScheme.dark : ColorScheme.light)(primary: t.accent, surface: t.pageBg),
        textTheme: GoogleFonts.hankenGroteskTextTheme(
            t.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
        scaffoldBackgroundColor: t.pageBg,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: _onboarded
          ? HomeScreen(t: t, places: _places, onToggleTheme: _toggleTheme)
          : OnboardingScreen(t: t, places: _places, onFinish: _finishOnboarding),
    );
  }
}
