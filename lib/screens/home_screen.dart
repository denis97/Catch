import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../data/places_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/line_badge.dart';
import '../widgets/legs_row.dart';
import '../widgets/pulse_dot.dart';
import '../services/location_service.dart';
import '../services/reminder_service.dart';
import '../services/transit_service.dart';
import 'detail_screen.dart';
import 'places_screen.dart';

/// Distance (m) within which the user counts as "at" a place.
const double _kNearbyMeters = 400;

class HomeScreen extends StatefulWidget {
  final AppTheme t;
  final PlacesRepository places;
  final VoidCallback? onToggleTheme;
  const HomeScreen({super.key, required this.t, required this.places, this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0=home, 1=work, 2+=favorites
  bool _auto = true;
  Timer? _ticker;
  List<Departure> _deps = [];
  bool _loading = true; // first-load only: full-screen spinner
  bool _busy = false;   // inline refresh: keep feed visible, dim it
  bool _usingLive = false;
  String? _previewReason;
  Position? _pos;
  DateTime? _posAt;     // when _pos was last acquired
  String? _destination; // destination param used for the current feed
  final Map<String, List<Departure>> _depsCache = {}; // keyed by destinationParam

  /// How long a GPS fix stays fresh enough to reuse for a destination switch.
  static const _posMaxAge = Duration(seconds: 60);

  final _transit  = TransitService();
  final _location = LocationService();

  @override
  void initState() {
    super.initState();
    widget.places.addListener(_onPlacesChanged);
    _fetch().then((_) => _prefetchOthers());
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    widget.places.removeListener(_onPlacesChanged);
    _ticker?.cancel();
    super.dispose();
  }

  void _onPlacesChanged() {
    if (_selectedIndex >= 2 && _selectedIndex - 2 >= widget.places.favorites.length) {
      _selectedIndex = 0;
      _auto = true;
    }
    _fetch().then((_) => _prefetchOthers());
  }

  AppTheme get t => widget.t;

  Place? get _selectedPlace {
    if (_selectedIndex == 0) return widget.places.home;
    if (_selectedIndex == 1) return widget.places.work;
    final favIdx = _selectedIndex - 2;
    final favs = widget.places.favorites;
    return favIdx < favs.length ? favs[favIdx] : null;
  }

  String get _headingLabel {
    if (_selectedIndex == 0) return 'Heading home';
    if (_selectedIndex == 1) return 'Heading to work';
    return 'Heading to ${_selectedPlace?.name ?? '...'}';
  }

  List<Place> get _otherPlaces {
    final sel = _selectedPlace;
    return [
      if (widget.places.home != null) widget.places.home!,
      if (widget.places.work != null) widget.places.work!,
      ...widget.places.favorites,
    ].where((p) => p.id != sel?.id).toList();
  }

  int _placeIndex(Place place) {
    if (place.kind == PlaceKind.home) return 0;
    if (place.kind == PlaceKind.work) return 1;
    final favIdx = widget.places.favorites.indexWhere((f) => f.id == place.id);
    return favIdx >= 0 ? 2 + favIdx : 0;
  }

  Future<void> _fetch({bool inline = false, bool forceLocation = false}) async {
    if (inline && mounted) setState(() => _busy = true);

    // Reuse the last fix for plain destination switches — your location
    // hasn't changed, so re-acquiring GPS just adds latency. Only re-fix when
    // forced (pull-to-refresh, auto re-eval), missing, or stale.
    Position? pos = _pos;
    final stale = _posAt == null || DateTime.now().difference(_posAt!) > _posMaxAge;
    if (pos == null || forceLocation || stale) {
      try {
        pos = await _location.getPosition();
      } catch (_) {
        pos = null;
      }
      _pos = pos;
      if (pos != null) _posAt = DateTime.now();
    }

    // Auto-switch between home/work based on proximity.
    if (_auto && pos != null && _selectedIndex < 2) {
      final home = widget.places.home;
      final work = widget.places.work;
      final distHome = home?.hasCoords == true
          ? Geolocator.distanceBetween(pos.latitude, pos.longitude, home!.lat!, home.lng!)
          : null;
      final distWork = work?.hasCoords == true
          ? Geolocator.distanceBetween(pos.latitude, pos.longitude, work!.lat!, work.lng!)
          : null;
      if (distHome != null && distHome < _kNearbyMeters) {
        _selectedIndex = 1; // at home → heading to work
      } else if (distWork != null && distWork < _kNearbyMeters) {
        _selectedIndex = 0; // at work → heading home
      }
    }

    final dest = _selectedPlace;

    String? reason;
    List<Departure>? live;

    final distToDest = (pos != null && dest?.hasCoords == true)
        ? Geolocator.distanceBetween(pos.latitude, pos.longitude, dest!.lat!, dest.lng!)
        : null;

    if (pos == null) {
      reason = 'Location unavailable';
    } else if (dest == null) {
      reason = _selectedIndex == 0 ? 'Set your Home address in Places'
          : _selectedIndex == 1 ? 'Set your Work address in Places'
          : 'This place has no address set';
    } else if (distToDest != null && distToDest < 200) {
      reason = _selectedIndex == 0 ? "You're already home"
          : _selectedIndex == 1 ? "You're already at work"
          : "You're already there";
    } else {
      try {
        live = await _transit.getDepartures(
          originLat:   pos.latitude,
          originLng:   pos.longitude,
          destination: dest.destinationParam,
        );
        if (live.isEmpty) {
          reason = 'No transit routes found';
          live = null;
        }
      } catch (_) {
        reason = 'Transit service unreachable';
      }
    }

    if (!mounted) return;
    final destParam = dest?.destinationParam;
    final freshDeps = live ?? (_selectedIndex == 1 ? kWorkDeps : kHomeDeps);
    setState(() {
      _destination   = destParam;
      _deps          = freshDeps;
      if (destParam != null) _depsCache[destParam] = freshDeps;
      _usingLive     = live != null;
      _previewReason = reason;
      _loading       = false;
      _busy          = false;
    });
  }

  Future<void> _prefetchOthers() async {
    final pos = _pos;
    if (pos == null) return;
    for (final place in _otherPlaces) {
      if (!mounted) return;
      if (_depsCache.containsKey(place.destinationParam)) continue;
      try {
        final deps = await _transit.getDepartures(
          originLat: pos.latitude,
          originLng: pos.longitude,
          destination: place.destinationParam,
        );
        if (mounted && deps.isNotEmpty) {
          setState(() => _depsCache[place.destinationParam] = deps);
        }
      } catch (_) {}
    }
  }

  Future<void> _remind(Departure d) async {
    final result = await ReminderService.instance.scheduleLeaveReminder(d);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(reminderMessage(result)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: t.pageBg,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: t.accent))
          : RefreshIndicator(
              color: t.accent,
              onRefresh: () {
                _depsCache.clear();
                TransitService.clearCache();
                return _fetch(forceLocation: true).then((_) => _prefetchOthers());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(18, top + 18, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ContextHeader(
                      t: t,
                      heading: _headingLabel,
                      auto: _auto,
                      onAutoTap: () {
                        setState(() => _auto = true);
                        _fetch(inline: true, forceLocation: true);
                      },
                      onPlaces: () {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PlacesScreen(
                                t: t, places: widget.places,
                                onToggleTheme: widget.onToggleTheme)));
                      },
                    ),
                    const SizedBox(height: 18),
                    if (_previewReason != null) ...[
                      _PreviewBanner(t: t, reason: _previewReason!, onRetry: () => _fetch(inline: true, forceLocation: true)),
                      const SizedBox(height: 14),
                    ],
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _busy ? 0.45 : 1.0,
                      child: IgnorePointer(
                        ignoring: _busy,
                        child: _deps.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DepartureHero(
                                    t: t, d: _deps.first,
                                    onTap: () => _openDetail(_deps.first),
                                    onRemind: () => _remind(_deps.first),
                                    onOpenMaps: _openMaps,
                                  ),
                                  if (_otherPlaces.isNotEmpty) ...[
                                    const SizedBox(height: 22),
                                    _SectionLabel(t: t, label: 'Other destinations'),
                                    _buildDestGrid(),
                                  ],
                                  if (_deps.length > 1) ...[
                                    const SizedBox(height: 22),
                                    _SectionLabel(t: t, label: 'If you miss it'),
                                    _FallbackCard(t: t, deps: _deps.skip(1).toList(), onTap: _openDetail),
                                  ],
                                ],
                              )
                            : Center(child: Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Text('No departures found', style: TextStyle(color: t.textSec)),
                              )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_busy) ...[
                          SizedBox(width: 13, height: 13,
                              child: CircularProgressIndicator(strokeWidth: 2, color: t.textTer)),
                          const SizedBox(width: 6),
                          Text('Updating…', style: TextStyle(fontSize: 12.5, color: t.textTer)),
                        ] else ...[
                          Icon(_usingLive ? Icons.wifi : Icons.wifi_off, size: 13, color: t.textTer),
                          const SizedBox(width: 5),
                          Text(_usingLive ? 'Live · updated just now' : 'Preview data',
                              style: TextStyle(fontSize: 12.5, color: t.textTer)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDestGrid() {
    final places = _otherPlaces;
    final rows = <Widget>[];
    for (int i = 0; i < places.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _DestinationGridCard(
            t: t,
            place: places[i],
            deps: _depsCache[places[i].destinationParam],
            onTap: () => _selectDestination(places[i]),
          )),
          const SizedBox(width: 12),
          if (i + 1 < places.length)
            Expanded(child: _DestinationGridCard(
              t: t,
              place: places[i + 1],
              deps: _depsCache[places[i + 1].destinationParam],
              onTap: () => _selectDestination(places[i + 1]),
            ))
          else
            const Expanded(child: SizedBox()),
        ],
      ));
    }
    return Column(children: rows);
  }

  void _selectDestination(Place place) {
    final cached = _depsCache[place.destinationParam];
    if (cached != null) {
      // Serve instantly from cache — no network call needed.
      setState(() {
        _selectedIndex = _placeIndex(place);
        _auto = false;
        _destination = place.destinationParam;
        _deps = cached;
      });
    } else {
      setState(() { _selectedIndex = _placeIndex(place); _auto = false; });
      _fetch(inline: true);
    }
  }

  Future<void> _openMaps() async {
    final place = _selectedPlace;
    if (place == null) return;
    final dest = Uri.encodeComponent(place.address);
    final destId = place.placeId != null ? '&destination_place_id=${place.placeId}' : '';
    final origin = _pos != null ? '&origin=${_pos!.latitude},${_pos!.longitude}' : '';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1$origin&destination=$dest$destId&travelmode=transit',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open Maps'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _openDetail(Departure d) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(
      t: t,
      departure: d,
      alts: _deps,
      originLat: _usingLive ? _pos?.latitude : null,
      originLng: _usingLive ? _pos?.longitude : null,
      destination: _usingLive ? _destination : null,
    )));
  }
}

// ─── Preview-data banner ───────────────────────────────────────

class _PreviewBanner extends StatelessWidget {
  final AppTheme t;
  final String reason;
  final VoidCallback onRetry;
  const _PreviewBanner({required this.t, required this.reason, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 8, 11),
      decoration: BoxDecoration(
        color: t.amberSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 17, color: t.amber),
          const SizedBox(width: 9),
          Expanded(
            child: Text('$reason — showing preview data',
                style: TextStyle(fontSize: 13, color: t.amber, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Retry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.amber)),
          ),
        ],
      ),
    );
  }
}

// ─── Context header ────────────────────────────────────────────

class _ContextHeader extends StatelessWidget {
  final AppTheme t;
  final String heading;
  final bool auto;
  final VoidCallback onAutoTap;
  final VoidCallback onPlaces;
  const _ContextHeader({
    required this.t, required this.heading,
    required this.auto, required this.onAutoTap, required this.onPlaces,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heading,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: t.text, letterSpacing: -0.6, height: 1.05),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  GestureDetector(
                    onTap: onAutoTap,
                    child: Container(
                      height: 22, padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: auto ? t.accentSoft : t.chipBg,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(auto ? Icons.my_location : Icons.touch_app_outlined,
                              size: 12, color: auto ? t.accent : t.textSec),
                          const SizedBox(width: 4),
                          Text(auto ? 'AUTO' : 'MANUAL',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: auto ? t.accent : t.textSec, letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    nowLabel,
                    style: TextStyle(fontSize: 13.5, color: t.textSec, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onPlaces,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: t.chipBg, shape: BoxShape.circle),
            child: Icon(Icons.settings_outlined, size: 20, color: t.textSec),
          ),
        ),
      ],
    );
  }
}

// ─── Destination grid card ─────────────────────────────────────

class _DestinationGridCard extends StatelessWidget {
  final AppTheme t;
  final Place place;
  final List<Departure>? deps;
  final VoidCallback onTap;
  const _DestinationGridCard({required this.t, required this.place, required this.deps, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hero = deps?.isNotEmpty == true ? deps!.first : null;
    final urgColor = hero != null ? t.urgencyColor(hero.leaveIn) : t.textTer;
    final icon = place.kind == PlaceKind.home
        ? Icons.home_outlined
        : place.kind == PlaceKind.work
            ? Icons.work_outline
            : Icons.star_outline;
    final subtitle = place.stop.isNotEmpty ? place.stop : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: t.border),
          boxShadow: t.shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: t.chipBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: t.textSec),
            ),
            const SizedBox(height: 8),
            Text(
              place.name,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text, letterSpacing: -0.2),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: t.textSec),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
            ] else
              const SizedBox(height: 8),
            if (hero != null) ...[
              LineBadge(line: hero.line, t: t, size: 22, mode: hero.mode),
              const SizedBox(height: 6),
              Text(leaveLabel(hero.leaveIn),
                  style: TextStyle(fontSize: 12, color: urgColor, fontWeight: FontWeight.w600)),
            ] else
              Text('—', style: TextStyle(fontSize: 12, color: t.textTer)),
          ],
        ),
      ),
    );
  }
}

// ─── Hero departure card ───────────────────────────────────────

class _DepartureHero extends StatelessWidget {
  final AppTheme t;
  final Departure d;
  final VoidCallback onTap;
  final VoidCallback onRemind;
  final VoidCallback? onOpenMaps;
  const _DepartureHero({required this.t, required this.d, required this.onTap, required this.onRemind, this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    final urgColor = t.urgencyColor(d.leaveIn);
    final urgBg    = t.urgencyBg(d.leaveIn);
    final animate  = d.leaveIn > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: t.border),
          boxShadow: t.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // urgency band
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: urgBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radius)),
              ),
              child: Row(
                children: [
                  PulseDot(color: urgColor, animate: animate),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      leaveLabel(d.leaveIn),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: urgColor, letterSpacing: -0.3),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onRemind,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    icon: Icon(Icons.notifications_none, size: 16, color: t.textSec),
                    label: Text('Remind me', style: TextStyle(fontSize: 13, color: t.textSec, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            // body
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      LineBadge(line: d.line, t: t, size: 30, mode: d.mode),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(d.headsign, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.text, letterSpacing: -0.2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(Icons.directions_walk, size: 15, color: t.textTer),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text('Board at ${d.from} · ${d.walk} min walk',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, color: t.textSec)),
                      ),
                    ],
                  ),
                  Divider(color: t.separator, height: 28),
                  Row(
                    children: [
                      Text('${d.depart} → ${d.arrive}',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: t.text,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('· ${d.duration} min · every ${d.every} min',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, color: t.textSec,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(child: LegsRow(legs: d.legs, t: t)),
                      if (onOpenMaps != null) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: onOpenMaps,
                          child: Container(
                            height: 26,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: t.chipBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_outlined, size: 13, color: t.textSec),
                                const SizedBox(width: 4),
                                Text('Maps', style: TextStyle(fontSize: 11.5, color: t.textSec, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── "If you miss it" fallback card ───────────────────────────

class _FallbackCard extends StatelessWidget {
  final AppTheme t;
  final List<Departure> deps;
  final ValueChanged<Departure> onTap;
  const _FallbackCard({required this.t, required this.deps, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: t.border),
        boxShadow: t.shadow,
      ),
      child: Column(
        children: [
          for (int i = 0; i < deps.length; i++)
            _DepartureRow(t: t, d: deps[i], isLast: i == deps.length - 1, onTap: () => onTap(deps[i])),
        ],
      ),
    );
  }
}

class _DepartureRow extends StatelessWidget {
  final AppTheme t;
  final Departure d;
  final bool isLast;
  final VoidCallback onTap;
  const _DepartureRow({required this.t, required this.d, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final urgColor = t.urgencyColor(d.leaveIn);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // time column
            SizedBox(
              width: 46,
              child: Padding(
                padding: const EdgeInsets.only(top: 13, right: 8),
                child: Text(d.depart, textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: t.text,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ),
            // rail column
            SizedBox(
              width: 22,
              child: Stack(
                children: [
                  Positioned(
                    left: 10, top: 0,
                    bottom: isLast ? null : 0,
                    height: isLast ? null : null,
                    child: Container(
                      width: 2,
                      height: isLast ? 24 : null,
                      color: t.separator,
                    ),
                  ),
                  if (isLast)
                    Positioned(left: 10, top: 24, bottom: 0, child: Container(width: 2, color: t.separator.withValues(alpha: 0))),
                  Positioned(
                    left: 6, top: 18,
                    child: Container(
                      width: 11, height: 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.card,
                        border: Border.all(color: urgColor, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // content column
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 12, 0, 12),
                decoration: BoxDecoration(
                  border: isLast ? null : Border(bottom: BorderSide(color: t.separator)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LineBadge(line: d.line, t: t, size: 24, mode: d.mode),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(d.headsign, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: t.text)),
                        ),
                        Text('arr ${d.arrive}',
                            style: TextStyle(fontSize: 13, color: t.textSec,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ],
                    ),
                    const SizedBox(height: 5),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: leaveLabel(d.leaveIn),
                            style: TextStyle(fontSize: 12.5, color: urgColor, fontWeight: FontWeight.w600)),
                        TextSpan(text: ' · every ${d.every} min · ${d.duration} min',
                            style: TextStyle(fontSize: 12.5, color: t.textTer, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ],
                ),
              ),
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
