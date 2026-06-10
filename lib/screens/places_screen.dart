import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/places_repository.dart';
import '../theme/app_theme.dart';
import 'address_search_screen.dart';

class PlacesScreen extends StatefulWidget {
  final AppTheme t;
  final PlacesRepository places;
  final VoidCallback? onToggleTheme;
  const PlacesScreen({super.key, required this.t, required this.places, this.onToggleTheme});

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
  PlacesRepository get repo => widget.places;

  void _toggleTheme() {
    setState(() => _dark = !_dark);
    widget.onToggleTheme?.call();
  }

  Future<void> _editAnchor(PlaceKind kind) async {
    final picked = await Navigator.push<PickedPlace>(
      context,
      MaterialPageRoute(builder: (_) => AddressSearchScreen(
        t: t,
        title: kind == PlaceKind.home ? 'Set Home' : 'Set Work',
      )),
    );
    if (picked == null) return;
    await repo.upsert(Place(
      id: kind.name,
      kind: kind,
      name: kind == PlaceKind.home ? 'Home' : 'Work',
      address: picked.address,
      lat: picked.lat,
      lng: picked.lng,
    ));
    if (mounted) setState(() {});
  }

  Future<void> _addFavorite() async {
    final picked = await Navigator.push<PickedPlace>(
      context,
      MaterialPageRoute(builder: (_) => AddressSearchScreen(t: t, title: 'Add a place')),
    );
    if (picked == null) return;
    await repo.upsert(Place(
      id: 'fav_${DateTime.now().millisecondsSinceEpoch}',
      kind: PlaceKind.star,
      name: picked.name,
      address: picked.address,
      lat: picked.lat,
      lng: picked.lng,
    ));
    if (mounted) setState(() {});
  }

  Future<void> _deleteFavorite(Place p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        title: Text('Remove ${p.name}?', style: TextStyle(color: t.text, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: t.textSec))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(color: Color(0xFFC24A3B), fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true) {
      await repo.remove(p.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final home = repo.home;
    final work = repo.work;
    final favs = repo.favorites;

    return Scaffold(
      backgroundColor: t.pageBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, top, 0, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackBar(t: t, title: 'Places', sub: 'Home & Work power your suggestions',
                onBack: () => Navigator.pop(context),
                trailing: GestureDetector(
                  onTap: _addFavorite,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: t.accentSoft, shape: BoxShape.circle),
                    child: Icon(Icons.add, size: 20, color: t.accent),
                  ),
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(t: t, label: 'Anchors'),
                  _Card(t: t, children: [
                    _AnchorRow(t: t, kind: PlaceKind.home, place: home, isLast: false,
                        onTap: () => _editAnchor(PlaceKind.home)),
                    _AnchorRow(t: t, kind: PlaceKind.work, place: work, isLast: true,
                        onTap: () => _editAnchor(PlaceKind.work)),
                  ]),
                  const SizedBox(height: 18),
                  if (favs.isNotEmpty) ...[
                    _SectionLabel(t: t, label: 'Favorites'),
                    _Card(t: t, children: [
                      for (int i = 0; i < favs.length; i++)
                        _FavoriteRow(t: t, place: favs[i], isLast: i == favs.length - 1,
                            onDelete: () => _deleteFavorite(favs[i])),
                    ]),
                    const SizedBox(height: 18),
                  ],
                  GestureDetector(
                    onTap: _addFavorite,
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
                  _Card(t: t, children: [
                    Padding(
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
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

class _Card extends StatelessWidget {
  final AppTheme t;
  final List<Widget> children;
  const _Card({required this.t, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: t.border),
        boxShadow: t.shadow,
      ),
      child: Column(children: children),
    );
  }
}

class _AnchorRow extends StatelessWidget {
  final AppTheme t;
  final PlaceKind kind;
  final Place? place;
  final bool isLast;
  final VoidCallback onTap;
  const _AnchorRow({required this.t, required this.kind, required this.place, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isHome = kind == PlaceKind.home;
    final tint   = isHome ? t.accent : const Color(0xFF2D6CDF);
    final icon   = isHome ? Icons.home_outlined : Icons.work_outline;
    final label  = isHome ? 'Home' : 'Work';
    final isSet  = place != null;

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
                color: isSet ? tint : t.chipBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 21, color: isSet ? Colors.white : t.textSec),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
                  const SizedBox(height: 1),
                  Text(
                    place?.address ?? 'Tap to set',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: isSet ? t.textSec : t.textTer),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(isSet ? Icons.edit_outlined : Icons.add, size: 17, color: t.textTer),
          ],
        ),
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  final AppTheme t;
  final Place place;
  final bool isLast;
  final VoidCallback onDelete;
  const _FavoriteRow({required this.t, required this.place, required this.isLast, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onDelete,
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
              decoration: BoxDecoration(color: t.chipBg, borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.star_outline, size: 21, color: t.textSec),
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
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.delete_outline, size: 18, color: t.textTer),
            ),
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
