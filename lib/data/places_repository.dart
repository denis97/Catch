import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Stores the user's places (Home, Work, favorites) in SharedPreferences.
class PlacesRepository extends ChangeNotifier {
  static const _key = 'places_v1';
  final SharedPreferences prefs;
  List<Place> _places = [];

  PlacesRepository(this.prefs) {
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _places = (jsonDecode(raw) as List<dynamic>)
            .map((e) => Place.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _places = [];
      }
    }
  }

  List<Place> get all => List.unmodifiable(_places);

  Place? get home => _firstOfKind(PlaceKind.home);
  Place? get work => _firstOfKind(PlaceKind.work);
  List<Place> get favorites =>
      _places.where((p) => p.kind == PlaceKind.star).toList();

  Place? _firstOfKind(PlaceKind k) {
    for (final p in _places) {
      if (p.kind == k) return p;
    }
    return null;
  }

  /// Inserts or replaces. Home and Work are singletons (keyed by kind);
  /// favorites are keyed by id.
  Future<void> upsert(Place place) async {
    if (place.kind == PlaceKind.star) {
      _places.removeWhere((p) => p.id == place.id);
    } else {
      _places.removeWhere((p) => p.kind == place.kind);
    }
    _places.add(place);
    await _save();
  }

  Future<void> remove(String id) async {
    _places.removeWhere((p) => p.id == id);
    await _save();
  }

  Future<void> _save() async {
    await prefs.setString(_key, jsonEncode(_places.map((p) => p.toJson()).toList()));
    notifyListeners();
  }
}
