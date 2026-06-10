import 'dart:math';
import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/places_repository.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/line_badge.dart';
import '../widgets/pill_button.dart';
import 'address_search_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final AppTheme t;
  final PlacesRepository places;
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.t, required this.places, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const int _total = 3;
  bool _requestingLocation = false;

  AppTheme get t => widget.t;

  void _next() {
    if (_step < _total - 1) {
      setState(() => _step++);
    } else {
      widget.onFinish();
    }
  }

  Future<void> _allowLocation() async {
    setState(() => _requestingLocation = true);
    await LocationService().getPosition(); // triggers the OS permission dialog
    if (!mounted) return;
    setState(() => _requestingLocation = false);
    _next();
  }

  Future<void> _editPlace(PlaceKind kind) async {
    final picked = await Navigator.push<PickedPlace>(
      context,
      MaterialPageRoute(builder: (_) => AddressSearchScreen(
        t: t,
        title: kind == PlaceKind.home ? 'Set Home' : 'Set Work',
      )),
    );
    if (picked == null) return;
    await widget.places.upsert(Place(
      id: kind.name,
      kind: kind,
      name: kind == PlaceKind.home ? 'Home' : 'Work',
      address: picked.address,
      lat: picked.lat,
      lng: picked.lng,
      placeId: picked.placeId,
    ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bot = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: t.pageBg,
      body: Padding(
        padding: EdgeInsets.fromLTRB(24, top + 14, 24, bot + 26),
        child: Column(
          children: [
            _dots(),
            Expanded(child: _body()),
            _buttons(),
          ],
        ),
      ),
    );
  }

  Widget _dots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_total, (i) {
          final active = i == _step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: active ? 22 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            decoration: BoxDecoration(
              color: active ? t.accent : t.chipBg,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }

  Widget _body() {
    if (_step == 0) return _stepWelcome();
    if (_step == 1) return _stepLocation();
    return _stepAnchors();
  }

  Widget _stepWelcome() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -2.5 * pi / 180,
          child: _PromiseCard(t: t),
        ),
        const SizedBox(height: 18),
        Text('Catch', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.4, color: t.text)),
        const SizedBox(height: 12),
        Text('Know when to leave.', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: t.text, letterSpacing: -0.3)),
        const SizedBox(height: 8),
        Text(
          'Your next ride home or to work —\nand the minute to walk out the door.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: t.textSec, height: 1.5),
        ),
      ],
    );
  }

  Widget _stepLocation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 92, height: 92,
          decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(28)),
          child: Icon(Icons.location_on_outlined, size: 46, color: t.accent),
        ),
        const SizedBox(height: 28),
        Text(
          'Find your stops automatically',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: t.text),
        ),
        const SizedBox(height: 12),
        Text(
          'Catch uses your location to show departures from the stops nearest you — and switches between Home and Work as your day moves.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: t.textSec, height: 1.5),
        ),
      ],
    );
  }

  Widget _stepAnchors() {
    final home = widget.places.home;
    final work = widget.places.work;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set your two anchors',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: t.text)),
        const SizedBox(height: 8),
        Text(
          'Home and Work power your daily suggestions. You can add more places anytime.',
          style: TextStyle(fontSize: 15, color: t.textSec, height: 1.5),
        ),
        const SizedBox(height: 24),
        _PlaceField(
          t: t, icon: Icons.home_outlined, label: 'Home',
          value: home?.address, placeholder: 'Add your home address',
          tint: t.accent, onTap: () => _editPlace(PlaceKind.home),
        ),
        const SizedBox(height: 12),
        _PlaceField(
          t: t, icon: Icons.work_outline, label: 'Work',
          value: work?.address, placeholder: 'Add your work address',
          tint: const Color(0xFF2D6CDF), onTap: () => _editPlace(PlaceKind.work),
        ),
      ],
    );
  }

  Widget _buttons() {
    final hasAnchors = widget.places.home != null && widget.places.work != null;
    final (String primary, String ghost) = switch (_step) {
      0 => ('Get started',    'I already have an account'),
      1 => ('Allow location', 'Enter location manually'),
      _ => ("I'm all set",    'Skip for now'),
    };
    final primaryEnabled = _step != 2 || hasAnchors;

    return Column(
      children: [
        Opacity(
          opacity: primaryEnabled ? 1 : 0.45,
          child: PillButton(
            t: t,
            label: _requestingLocation ? 'Requesting…' : primary,
            onTap: () {
              if (!primaryEnabled || _requestingLocation) return;
              if (_step == 1) {
                _allowLocation();
              } else {
                _next();
              }
            },
          ),
        ),
        const SizedBox(height: 6),
        PillButton(t: t, label: ghost, ghost: true, height: 46,
            onTap: _step == 1 ? _next : widget.onFinish),
      ],
    );
  }
}

class _PromiseCard extends StatelessWidget {
  final AppTheme t;
  const _PromiseCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x2E101418), blurRadius: 60, offset: Offset(0, 24))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LineBadge(line: '14B', t: t, size: 28),
              const SizedBox(width: 9),
              Text('Maple Heights', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: t.text)),
              const Spacer(),
              Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: t.accent)),
            ],
          ),
          const SizedBox(height: 13),
          Text('LEAVE IN', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1, color: t.accent)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('6', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: t.accent,
                  fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(width: 5),
              Text('min', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.accent)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Arrive home by 5:56', style: TextStyle(fontSize: 12, color: t.textTer,
              fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

class _PlaceField extends StatelessWidget {
  final AppTheme t;
  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final Color tint;
  final VoidCallback onTap;
  const _PlaceField({
    required this.t, required this.icon, required this.label,
    required this.value, required this.placeholder,
    required this.tint, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
          boxShadow: t.shadow,
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: t.textTer, letterSpacing: 0.5)),
                  const SizedBox(height: 1),
                  Text(
                    value ?? placeholder,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isSet ? t.text : t.textTer),
                  ),
                ],
              ),
            ),
            Icon(isSet ? Icons.check : Icons.add, size: 20, color: isSet ? t.accent : t.textTer),
          ],
        ),
      ),
    );
  }
}
