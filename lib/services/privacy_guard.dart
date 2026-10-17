/// Detects phone numbers and addresses in chat messages so the app can warn
/// the sender before they share them.
class PrivacyGuard {
  static final _phone = RegExp(r'\+?\d[\d\s\-]{6,}\d');
  static final _street = RegExp(
    r'\b(jalan|jln|lorong|lrg|persiaran|lebuh|taman)\b',
    caseSensitive: false,
  );
  static final _unit = RegExp(
    r'\b(no\.?|lot|unit|blok|block)\s*[a-z]?[\w-]*\d',
    caseSensitive: false,
  );

  static bool hasPhoneNumber(String text) {
    for (final m in _phone.allMatches(text)) {
      final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 8) return true;
    }
    return false;
  }

  static bool hasAddress(String text) =>
      _street.hasMatch(text) || _unit.hasMatch(text);

  static bool looksSensitive(String text) =>
      hasPhoneNumber(text) || hasAddress(text);
}
