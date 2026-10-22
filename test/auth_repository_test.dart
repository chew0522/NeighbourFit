import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourfit/data/local/auth_repository.dart';
import 'package:neighbourfit/data/local/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AuthRepository auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    auth = AuthRepository(LocalStore(await SharedPreferences.getInstance()));
  });

  test('registers and logs in, ignoring email case and spaces', () async {
    await auth.register(
      email: 'Mei@Example.com ',
      password: 'secret1',
      userId: 'u1',
    );
    expect(auth.login('mei@example.com', 'secret1'), 'u1');
    expect(auth.login('  MEI@example.COM', 'secret1'), 'u1');
  });

  test('wrong password or unknown email returns null', () async {
    await auth.register(email: 'a@b.co', password: 'secret1', userId: 'u1');
    expect(auth.login('a@b.co', 'wrong'), isNull);
    expect(auth.login('x@y.co', 'secret1'), isNull);
  });

  test('detects a taken email and never stores the plain password', () async {
    await auth.register(email: 'a@b.co', password: 'secret1', userId: 'u1');
    expect(auth.emailTaken('A@B.co'), isTrue);
    expect(auth.emailTaken('other@b.co'), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nf_auth')!.contains('secret1'), isFalse);
  });
}
