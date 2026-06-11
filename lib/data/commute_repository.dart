import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Stores the user's commute alert windows in SharedPreferences.
class CommuteRepository extends ChangeNotifier {
  static const _key = 'commute_alerts_v1';
  final SharedPreferences prefs;
  List<CommuteAlert> _alerts = [];

  CommuteRepository(this.prefs) {
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _alerts = (jsonDecode(raw) as List<dynamic>)
            .map((e) => CommuteAlert.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _alerts = [];
      }
    }
  }

  List<CommuteAlert> get all => List.unmodifiable(_alerts);

  Future<void> upsert(CommuteAlert alert) async {
    _alerts.removeWhere((a) => a.id == alert.id);
    _alerts.add(alert);
    await _save();
  }

  Future<void> remove(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    await _save();
  }

  Future<void> _save() async {
    await prefs.setString(_key, jsonEncode(_alerts.map((a) => a.toJson()).toList()));
    notifyListeners();
  }
}
