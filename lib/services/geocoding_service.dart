import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class GeocodingService {
  static Future<String> reverseGeocode(double lat, double lng) async {
    if (!AppConfig.hasKakaoKey) {
      return _coordText(lat, lng);
    }

    try {
      final uri = Uri.parse(
        'https://dapi.kakao.com/v2/local/geo/coord2address.json'
        '?x=$lng&y=$lat&input_coord=WGS84',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'KakaoAK ${AppConfig.kakaoRestApiKey}'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final docs = data['documents'] as List;
        if (docs.isNotEmpty) {
          final doc = docs[0] as Map<String, dynamic>;
          final road = doc['road_address'] as Map<String, dynamic>?;
          final addr = doc['address'] as Map<String, dynamic>?;
          final name = road?['address_name'] ?? addr?['address_name'];
          if (name != null) return name as String;
        }
      }
    } catch (_) {}

    return _coordText(lat, lng);
  }

  static String _coordText(double lat, double lng) =>
      '위도 ${lat.toStringAsFixed(5)}\n경도 ${lng.toStringAsFixed(5)}';
}
