import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';

class PlacesScreen extends StatefulWidget {
  final AppTheme t;
  final VoidCallback? onToggleTheme;
  const PlacesScreen({super.key, required this.t, this.onToggleTheme});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  late bool _dark;

  @override
  void initState() {
    super.initState();
    _dark = widget.t.dark;
  }

  AppTheme get t => AppTheme(accent: widget.t.accent, dark: _dark);

  void _toggleTheme() {
    setState(() => _dark = !_dark);
    widget.onToggleTheme?.call();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final anchors = kPlaces.where((p) => p.kind != PlaceKind.star).toList();
    final favs    = kPlaces.where((p) => p.kind == PlaceKind.star).toList();

    return Scaffold(
      backgroundColor: t.pageBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, top, 0, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackBar(t: t, title: 'Places', sub: 'Home & Work power your suggestions',
                onBack: () => Navigator.pop(context),
                trailing: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: t.accentSoft, shape: BoxShape.circle),
                  child: Icon(Icons.add, size: 20, color: t.accent),
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(t: t, label: 'Anchors'),
                  _PlaceCard(t: t, places: anchors, onTap: (p) => _open(context, p)),
                  const SizedBox(height: 18),
                  _SectionLabel(t: t, label: 'Favorites'),
                  _PlaceCard(t: t, places: favs, onTap: (p) => _open(context, p)),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: t.border, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18, color: t.textSec),
                          const SizedBox(width: 8),
                          Text('Add a place', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.textSec)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel(t: t, label: 'Appearance'),
                  Container(
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: t.border),
                      boxShadow: t.shadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: t.chipBg, borderRadius: BorderRadius.circular(13)),
                            child: Icon(_dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 21, color: t.textSec),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(_dark ? 'Dark mode' : 'Light mode',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
                          ),
                          Switch(
                            value: _dark,
                            onChanged: (_) => _toggleTheme(),
                            activeColor: t.accent,
                            activeTrackColor: t.accentSoft,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Place p) {
    final dep = p.kind == PlaceKind.work ? kWorkDeps.first : kHomeDeps.first;
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(t: t, departure: dep)));
  }
}

class _BackBar extends StatelessWidget {
  final AppTheme t;
  final String title;
  final String sub;
  final VoidCallback onBack;
  final Widget trailing;
  const _BackBar({required this.t, required this.title, required this.sub, required this.onBack, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: t.pageBg,
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: t.accent, size: 28),
            onPressed: onBack,
            padding: const EdgeInsets.only(right: 4),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: t.text, height: 1.1)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 12.5, color: t.textSec)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final AppTheme t;
  final List<Place> places;
  final ValueChanged<Place> onTap;
  const _PlaceCard({required this.t, required this.places, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: t.border),
        boxShadow: t.shadow,
      ),
      child: Column(
        children: [
          for (int i = 0; i < places.length; i++)
            _PlaceRow(t: t, place: places[i], isLast: i == places.length - 1, onTap: () => onTap(places[i])),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  final AppTheme t;
  final Place place;
  final bool isLast;
  final VoidCallback onTap;
  const _PlaceRow({required this.t, required this.place, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (place.kind) {
      PlaceKind.home => (Icons.home_outlined,   t.accent),
      PlaceKind.work => (Icons.work_outline,     const Color(0xFF2D6CDF)),
      PlaceKind.star => (Icons.star_outline,     t.textSec),
    };
    final isStar = place.kind == PlaceKind.star;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: t.separator)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isStar ? t.chipBg : tint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 21, color: isStar ? t.textSec : Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
                  const SizedBox(height: 1),
                  Text(place.address, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: t.textSec)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_walk, size: 13, color: t.textTer),
                    const SizedBox(width: 4),
                    Text('${place.walk} min', style: TextStyle(fontSize: 12, color: t.textTer)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(place.stop, style: TextStyle(fontSize: 12, color: t.textTer)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 17, color: t.textTer),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final AppTheme t;
  final String label;
  const _SectionLabel({required this.t, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label.toUpperCase(),
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: t.textTer)),
    );
  }
}
