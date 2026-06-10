import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class PlacesApiException implements Exception {
  final String message;
  PlacesApiException(this.message);
  @override
  String toString() => message;
}

class PlaceSuggestion {
  final String placeId;
  final String primary;
  final String secondary;
  const PlaceSuggestion({required this.placeId, required this.primary, required this.secondary});
}

class PlaceDetails {
  final String name;
  final String address;
  final double lat;
  final double lng;
  const PlaceDetails({required this.name, required this.address, required this.lat, required this.lng});
}

class PlacesService {
  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': input,
      'key': kGoogleMapsApiKey,
    });

    final body = await _get(uri);
    final status = body['status'] as String;
    if (status == 'ZERO_RESULTS') return [];
    if (status != 'OK') {
      throw PlacesApiException(_friendly(status));
    }

    final preds = body['predictions'] as List<dynamic>? ?? [];
    return preds.map((p) {
      final m = p as Map<String, dynamic>;
      final fmt = m['structured_formatting'] as Map<String, dynamic>? ?? {};
      return PlaceSuggestion(
        placeId:   m['place_id'] as String,
        primary:   (fmt['main_text']      as String?) ?? (m['description'] as String? ?? ''),
        secondary: (fmt['secondary_text'] as String?) ?? '',
      );
    }).toList();
  }

  Future<PlaceDetails> details(String placeId) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields': 'name,formatted_address,geometry/location',
      'key': kGoogleMapsApiKey,
    });

    final body = await _get(uri);
    final status = body['status'] as String;
    if (status != 'OK') throw PlacesApiException(_friendly(status));

    final result = body['result'] as Map<String, dynamic>;
    final loc = ((result['geometry'] as Map<String, dynamic>)['location']) as Map<String, dynamic>;
    return PlaceDetails(
      name:    (result['name'] as String?) ?? '',
      address: (result['formatted_address'] as String?) ?? '',
      lat:     (loc['lat'] as num).toDouble(),
      lng:     (loc['lng'] as num).toDouble(),
    );
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    late http.Response resp;
    try {
      resp = await http.get(uri).timeout(const Duration(seconds: 8));
    } catch (_) {
      throw PlacesApiException('No connection — check your network.');
    }
    if (resp.statusCode != 200) {
      throw PlacesApiException('Search unavailable (HTTP ${resp.statusCode}).');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  String _friendly(String status) {
    switch (status) {
      case 'REQUEST_DENIED':
        return 'Search unavailable — Places API not enabled or invalid key.';
      case 'OVER_QUERY_LIMIT':
        return 'Search limit reached — try again later.';
      case 'INVALID_REQUEST':
        return 'Invalid search.';
      default:
        return 'Search failed ($status).';
    }
  }
}
