import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/commute_repository.dart';
import '../data/models.dart';
import '../data/places_repository.dart';
import '../services/commute_service.dart';
import '../services/reminder_service.dart';
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
  late CommuteRepository _commutes;

  @override
  void initState() {
    super.initState();
    _dark = widget.t.dark;
    _commutes = CommuteRepository(widget.places.prefs);
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
      placeId: picked.placeId,
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
      placeId: picked.placeId,
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

  Future<void> _addCommuteAlert() async {
    final anchors = repo.all.where((p) => p.hasCoords).toList();
    if (anchors.isEmpty || repo.all.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Set at least two places first (e.g. Home and Work)'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final alert = await showModalBottomSheet<CommuteAlert>(
      context: context,
      backgroundColor: t.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CommuteEditorSheet(t: t, places: repo),
    );
    if (alert == null) return;
    await _commutes.upsert(alert);
    await CommuteService.reschedule();
    if (mounted) setState(() {});
    await _ensureCommutePermissions();
  }

  Future<void> _toggleCommuteAlert(CommuteAlert a, bool on) async {
    await _commutes.upsert(a.copyWith(enabled: on));
    await CommuteService.reschedule();
    if (mounted) setState(() {});
  }

  Future<void> _deleteCommuteAlert(CommuteAlert a) async {
    await _commutes.remove(a.id);
    await CommuteService.reschedule();
    if (mounted) setState(() {});
  }

  /// Commute alerts need notifications and "all the time" location to work
  /// while the app is closed. Walks the user through both.
  Future<void> _ensureCommutePermissions() async {
    await ReminderService.instance.init();
    await ReminderService.instance.requestPermission();

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.always || !mounted) return;

    final goToSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        title: Text('Allow location all the time',
            style: TextStyle(color: t.text, fontWeight: FontWeight.w700)),
        content: Text(
          'Commute alerts check where you are while the app is closed. '
          'In settings, set location access to "Allow all the time".',
          style: TextStyle(color: t.textSec),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Later', style: TextStyle(color: t.textSec))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Open settings',
                  style: TextStyle(color: t.accent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (goToSettings == true) await Geolocator.openAppSettings();
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
                  _SectionLabel(t: t, label: 'Commute alerts'),
                  if (_commutes.all.isNotEmpty) ...[
                    _Card(t: t, children: [
                      for (int i = 0; i < _commutes.all.length; i++)
                        _CommuteRow(
                          t: t,
                          alert: _commutes.all[i],
                          places: repo,
                          isLast: i == _commutes.all.length - 1,
                          onToggle: (on) => _toggleCommuteAlert(_commutes.all[i], on),
                          onDelete: () => _deleteCommuteAlert(_commutes.all[i]),
                        ),
                    ]),
                    const SizedBox(height: 12),
                  ],
                  GestureDetector(
                    onTap: _addCommuteAlert,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: t.border, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_active_outlined, size: 18, color: t.textSec),
                          const SizedBox(width: 8),
                          Text('Add commute alert', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.textSec)),
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

// ── Commute alerts ─────────────────────────────────────────────

String _fmtHM(int min) =>
    '${(min ~/ 60).toString().padLeft(2, '0')}:${(min % 60).toString().padLeft(2, '0')}';

const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

String _daysLabel(List<int> days) {
  if (days.length == 7) return 'Every day';
  const weekdays = [1, 2, 3, 4, 5];
  if (days.length == 5 && weekdays.every(days.contains)) return 'Mon–Fri';
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final sorted = [...days]..sort();
  return sorted.map((d) => names[d - 1]).join(' ');
}

class _CommuteRow extends StatelessWidget {
  final AppTheme t;
  final CommuteAlert alert;
  final PlacesRepository places;
  final bool isLast;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  const _CommuteRow({
    required this.t, required this.alert, required this.places,
    required this.isLast, required this.onToggle, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final at = places.byId(alert.atPlaceId);
    final to = places.byId(alert.toPlaceId);
    final title = '${at?.name ?? '?'} → ${to?.name ?? '?'}';
    final sub = '${_fmtHM(alert.startMin)}–${_fmtHM(alert.endMin)} · ${_daysLabel(alert.days)}';

    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: t.separator)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.notifications_active_outlined, size: 20, color: t.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: t.text)),
                  const SizedBox(height: 2),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: t.textSec)),
                ],
              ),
            ),
            Switch(
              value: alert.enabled,
              onChanged: onToggle,
              activeColor: t.accent,
              activeTrackColor: t.accentSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommuteEditorSheet extends StatefulWidget {
  final AppTheme t;
  final PlacesRepository places;
  const _CommuteEditorSheet({required this.t, required this.places});

  @override
  State<_CommuteEditorSheet> createState() => _CommuteEditorSheetState();
}

class _CommuteEditorSheetState extends State<_CommuteEditorSheet> {
  late String _atId;
  late String _toId;
  int _startMin = 17 * 60;
  int _endMin = 18 * 60;
  final Set<int> _days = {1, 2, 3, 4, 5};

  AppTheme get t => widget.t;

  /// Anchor must have coords (geofence); destination can be any place.
  List<Place> get _anchorOptions =>
      widget.places.all.where((p) => p.hasCoords).toList();
  List<Place> get _destOptions =>
      widget.places.all.where((p) => p.id != _atId).toList();

  @override
  void initState() {
    super.initState();
    final work = widget.places.work;
    final home = widget.places.home;
    _atId = (work?.hasCoords == true ? work : _anchorOptions.first)!.id;
    _toId = (home != null && home.id != _atId)
        ? home.id
        : widget.places.all.firstWhere((p) => p.id != _atId).id;
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _startMin : _endMin;
    final res = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (res == null) return;
    setState(() {
      if (start) {
        _startMin = res.hour * 60 + res.minute;
        if (_endMin <= _startMin) _endMin = (_startMin + 60).clamp(0, 24 * 60);
      } else {
        _endMin = res.hour * 60 + res.minute;
      }
    });
  }

  void _save() {
    if (_days.isEmpty || _endMin <= _startMin) return;
    Navigator.pop(context, CommuteAlert(
      id: 'cw_${DateTime.now().millisecondsSinceEpoch}',
      atPlaceId: _atId,
      toPlaceId: _toId,
      startMin: _startMin,
      endMin: _endMin,
      days: _days.toList()..sort(),
    ));
  }

  Widget _placeDropdown({
    required String label,
    required String value,
    required List<Place> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: t.textTer)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: t.card,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.text),
              items: [
                for (final p in options)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) { if (v != null) onChanged(v); },
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeBox(String label, int min, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: Column(
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: t.textTer)),
              const SizedBox(height: 4),
              Text(_fmtHM(min),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: t.text)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 22 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commute alert',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: t.text)),
          const SizedBox(height: 4),
          Text('Shows the next departure on your lock screen when you are here during this window.',
              style: TextStyle(fontSize: 13, color: t.textSec)),
          const SizedBox(height: 18),
          _placeDropdown(
            label: 'When I am at',
            value: _atId,
            options: _anchorOptions,
            onChanged: (v) => setState(() {
              _atId = v;
              if (_toId == v) _toId = _destOptions.first.id;
            }),
          ),
          const SizedBox(height: 14),
          _placeDropdown(
            label: 'Going to',
            value: _toId,
            options: _destOptions,
            onChanged: (v) => setState(() => _toId = v),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _timeBox('From', _startMin, () => _pickTime(true)),
              const SizedBox(width: 10),
              _timeBox('Until', _endMin, () => _pickTime(false)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int d = 1; d <= 7; d++)
                GestureDetector(
                  onTap: () => setState(() {
                    if (!_days.remove(d)) _days.add(d);
                  }),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _days.contains(d) ? t.accent : Colors.transparent,
                      border: Border.all(color: _days.contains(d) ? t.accent : t.border, width: 1.5),
                    ),
                    child: Center(
                      child: Text(_dayLetters[d - 1],
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: _days.contains(d) ? Colors.white : t.textSec,
                          )),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _save,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: (_days.isEmpty || _endMin <= _startMin) ? t.chipBg : t.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text('Save alert',
                    style: TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700,
                      color: (_days.isEmpty || _endMin <= _startMin) ? t.textTer : Colors.white,
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
