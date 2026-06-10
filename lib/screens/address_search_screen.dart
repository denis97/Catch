import 'dart:async';
import 'package:flutter/material.dart';
import '../services/places_service.dart';
import '../theme/app_theme.dart';

/// What the user picked: either a resolved place (with coords) or a
/// manually typed address (no coords).
class PickedPlace {
  final String name;
  final String address;
  final double? lat;
  final double? lng;
  const PickedPlace({required this.name, required this.address, this.lat, this.lng});
}

class AddressSearchScreen extends StatefulWidget {
  final AppTheme t;
  final String title;
  const AddressSearchScreen({super.key, required this.t, required this.title});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final _controller = TextEditingController();
  final _places = PlacesService();
  Timer? _debounce;
  late String _sessionToken;
  List<PlaceSuggestion> _suggestions = [];
  String? _error;
  bool _searching = false;
  bool _resolving = false;

  AppTheme get t => widget.t;

  @override
  void initState() {
    super.initState();
    _sessionToken = PlacesService.newSessionToken();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String input) {
    _debounce?.cancel();
    if (input.trim().length < 3) {
      setState(() { _suggestions = []; _error = null; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(input.trim()));
  }

  Future<void> _search(String input) async {
    try {
      final results = await _places.autocomplete(input, sessionToken: _sessionToken);
      if (!mounted) return;
      setState(() { _suggestions = results; _error = null; _searching = false; });
    } on PlacesApiException catch (e) {
      if (!mounted) return;
      setState(() { _suggestions = []; _error = e.message; _searching = false; });
    }
  }

  Future<void> _pick(PlaceSuggestion s) async {
    setState(() => _resolving = true);
    try {
      final d = await _places.details(s.placeId, sessionToken: _sessionToken);
      if (!mounted) return;
      Navigator.pop(context, PickedPlace(name: d.name, address: d.address, lat: d.lat, lng: d.lng));
    } on PlacesApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _resolving = false; });
    }
  }

  void _useTyped() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, PickedPlace(name: text, address: text));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final typed = _controller.text.trim();

    return Scaffold(
      backgroundColor: t.pageBg,
      body: Column(
        children: [
          // header
          Container(
            padding: EdgeInsets.fromLTRB(12, top + 6, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: t.accent, size: 28),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.only(right: 4),
                ),
                Expanded(
                  child: Text(widget.title,
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: t.text)),
                ),
              ],
            ),
          ),
          // search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border),
                boxShadow: t.shadow,
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20, color: t.textTer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: _onChanged,
                      autofocus: true,
                      style: TextStyle(fontSize: 16, color: t.text),
                      decoration: InputDecoration(
                        hintText: 'Search address or place',
                        hintStyle: TextStyle(color: t.textTer),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searching || _resolving)
                    SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: t.accent)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // error banner with manual fallback
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.amberSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 17, color: t.amber),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(fontSize: 13, color: t.amber, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          // results
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                for (final s in _suggestions)
                  _SuggestionRow(t: t, suggestion: s, onTap: () => _pick(s)),
                // Manual entry always available once something is typed
                if (typed.length >= 3)
                  GestureDetector(
                    onTap: _useTyped,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: t.chipBg, borderRadius: BorderRadius.circular(11)),
                            child: Icon(Icons.edit_outlined, size: 18, color: t.textSec),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Use "$typed"',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.textSec)),
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
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final AppTheme t;
  final PlaceSuggestion suggestion;
  final VoidCallback onTap;
  const _SuggestionRow({required this.t, required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.separator))),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(11)),
              child: Icon(Icons.place_outlined, size: 18, color: t.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(suggestion.primary,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
                  if (suggestion.secondary.isNotEmpty)
                    Text(suggestion.secondary, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: t.textSec)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 17, color: t.textTer),
          ],
        ),
      ),
    );
  }
}
