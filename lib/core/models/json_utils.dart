List<String> strList(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

DateTime parseDt(Object? v, [DateTime? fallback]) {
  if (v is String) {
    final d = DateTime.tryParse(v);
    if (d != null) return d;
  }
  return fallback ?? DateTime.now();
}

DateTime? parseDtOrNull(Object? v) {
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Accepts "#RRGGBB" strings (seed files) or ints (saved data).
int parseColor(Object? v, [int fallback = 0xFF2E9E6B]) {
  if (v is int) return v;
  if (v is String) {
    final hex = v.replaceFirst('#', '');
    final n = int.tryParse(hex, radix: 16);
    if (n != null) return hex.length <= 6 ? (0xFF000000 | n) : n;
  }
  return fallback;
}

Map<String, dynamic> asMap(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> mapList(Object? v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];
