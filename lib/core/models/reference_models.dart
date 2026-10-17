import 'json_utils.dart';

class Community {
  const Community({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;

  factory Community.fromJson(Map<String, dynamic> j) => Community(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
      );
}

class PresetLocation {
  const PresetLocation({
    required this.id,
    required this.name,
    required this.communityId,
    required this.lat,
    required this.lng,
    this.accessibilityNotes = '',
  });

  final String id;
  final String name;
  final String communityId;
  final double lat;
  final double lng;
  final String accessibilityNotes;

  String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  factory PresetLocation.fromJson(Map<String, dynamic> j) => PresetLocation(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        communityId: j['communityId'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        accessibilityNotes: j['accessibilityNotes'] as String? ?? '',
      );
}

class Voucher {
  const Voucher({
    required this.id,
    required this.merchant,
    required this.title,
    required this.pointsCost,
  });

  final String id;
  final String merchant;
  final String title;
  final int pointsCost;

  factory Voucher.fromJson(Map<String, dynamic> j) => Voucher(
        id: j['id'] as String,
        merchant: j['merchant'] as String? ?? '',
        title: j['title'] as String? ?? '',
        pointsCost: (j['pointsCost'] as num?)?.toInt() ?? 0,
      );
}

/// Reference data loaded from assets once at start-up.
class ReferenceData {
  const ReferenceData({
    required this.communities,
    required this.locations,
    required this.vouchers,
    required this.residentCodes,
  });

  final List<Community> communities;
  final List<PresetLocation> locations;
  final List<Voucher> vouchers;
  final List<String> residentCodes;

  Community? community(String id) {
    for (final c in communities) {
      if (c.id == id) return c;
    }
    return null;
  }

  PresetLocation? location(String? id) {
    if (id == null) return null;
    for (final l in locations) {
      if (l.id == id) return l;
    }
    return null;
  }

  Voucher? voucher(String id) {
    for (final v in vouchers) {
      if (v.id == id) return v;
    }
    return null;
  }

  factory ReferenceData.fromJson(
    Map<String, dynamic> locationsJson,
    List<dynamic> vouchersJson,
  ) =>
      ReferenceData(
        communities:
            mapList(locationsJson['communities']).map(Community.fromJson).toList(),
        locations: mapList(locationsJson['locations'])
            .map(PresetLocation.fromJson)
            .toList(),
        vouchers: vouchersJson
            .whereType<Map>()
            .map((e) => Voucher.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        residentCodes: strList(locationsJson['residentCodes']),
      );
}
