import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourfit/core/models/post.dart';
import 'package:neighbourfit/data/local/local_repositories.dart';
import 'package:neighbourfit/data/local/local_store.dart';
import 'package:neighbourfit/data/seed_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'post_pic files are matched to posts by name (p-s1.jpg -> p_s1)',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());
      await SeedLoader(store).seed();
      final posts = LocalPostRepository(store).load();
      Post byId(String id) => posts.firstWhere((p) => p.id == id);

      expect(byId('p_s1').photoPath, 'post_pic/p-s1.jpg');
      expect(byId('p_s9').photoPath, 'post_pic/p-s9.jpg');
      expect(byId('p_m8').photoPath, 'post_pic/p-m8.jpg');
      // Underscore file names work too (p_ml1.jpg, p_e1.jpg).
      for (final id in [
        'p_ml1',
        'p_ml2',
        'p_ml3',
        'p_ml4',
        'p_e1',
        'p_e2',
        'p_e3',
        'p_e4',
      ]) {
        expect(byId(id).photoPath, 'post_pic/$id.jpg', reason: id);
      }
      // Posts without a matching file stay without a photo.
      expect(byId('p_m1').photoPath, isNull);
    },
  );

  test('stale saved data gets its seed photos on the next launch', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final loader = SeedLoader(store);
    await loader.seed();

    // Simulate data saved before the photos were in the build, plus a photo the
    // user added to their own post.
    final repo = LocalPostRepository(store);
    final stale = [
      for (final p in repo.load())
        p.id == 'p_ml4'
            ? Post.fromJson({...p.toJson(), 'photoPath': null})
            : p.id == 'p_s8'
            ? Post.fromJson({
                ...p.toJson(),
                'photoPath': '/data/user/photo.jpg',
              })
            : p,
    ];
    await repo.save(stale);

    await loader.ensureSeeded();
    final posts = repo.load();
    expect(
      posts.firstWhere((p) => p.id == 'p_ml4').photoPath,
      'post_pic/p_ml4.jpg',
    );
    expect(
      posts.firstWhere((p) => p.id == 'p_s8').photoPath,
      '/data/user/photo.jpg',
    );
  });
}
