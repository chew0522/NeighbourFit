import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourfit/services/privacy_guard.dart';

void main() {
  test('flags phone numbers', () {
    expect(PrivacyGuard.looksSensitive('call me 012-345 6789'), isTrue);
    expect(PrivacyGuard.looksSensitive('my number is +60123456789'), isTrue);
  });

  test('flags address patterns', () {
    expect(PrivacyGuard.looksSensitive('I live at No. 12 Jalan Mawar'), isTrue);
    expect(PrivacyGuard.looksSensitive('Block C, unit 5-3'), isTrue);
  });

  test('ignores normal chat', () {
    expect(
      PrivacyGuard.looksSensitive('See you at 6:30 at the park!'),
      isFalse,
    );
    expect(PrivacyGuard.looksSensitive('We walked 10000 steps'), isFalse);
    expect(
      PrivacyGuard.looksSensitive('Is the path stroller-friendly?'),
      isFalse,
    );
  });
}
