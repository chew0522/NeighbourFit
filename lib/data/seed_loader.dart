import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/models/json_utils.dart';
import '../core/utils/time_utils.dart';
import 'local/local_repositories.dart';
import 'local/local_store.dart';

/// Seeds demo data on first launch and on "Reset demo data". Dates in the seed
/// files are offsets from now, so meetups are never already in the past.
class SeedLoader {
  SeedLoader(this.store, {AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  final LocalStore store;
  final AssetBundle bundle;

  static const _version = '13';

  Future<dynamic> _json(String name) async =>
      jsonDecode(await bundle.loadString('assets/seed/$name'));

  Future<void> ensureSeeded() async {
    if (store.getString(StoreKeys.seedVersion) != _version) {
      await seed();
      return;
    }
    await syncPhotos();
  }

  /// Every file in post_pic/ belongs to the post with the same name, with "-"
  /// standing for "_" (p-s1.jpg -> p_s1). Returns post id -> asset path.
  Future<Map<String, String>> _photoMap() async {
    final photos = <String, String>{};
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      for (final path in manifest.listAssets()) {
        if (!path.startsWith('post_pic/')) continue;
        final file = path.substring('post_pic/'.length);
        final dot = file.lastIndexOf('.');
        final name = (dot < 0 ? file : file.substring(0, dot))
            .replaceAll('-', '_')
            .toLowerCase();
        photos[name] = path;
      }
    } catch (_) {}
    return photos;
  }

  /// Keeps seeded posts in step with the files in post_pic/ without wiping
  /// anything: photos are added when a file exists and dropped when the file
  /// is gone. Posts with a photo the user added themselves are left alone.
  Future<void> syncPhotos() async {
    final photos = await _photoMap();
    final list = store.readList(StoreKeys.posts);
    var changed = false;
    for (final p in list) {
      final id = (p['id'] as String? ?? '').toLowerCase();
      final current = p['photoPath'] as String?;
      final wanted = photos[id];
      if (wanted != null &&
          current != wanted &&
          (current == null || current.startsWith('post_pic/'))) {
        p['photoPath'] = wanted;
        changed = true;
      } else if (wanted == null &&
          current != null &&
          current.startsWith('post_pic/')) {
        p['photoPath'] = null;
        changed = true;
      }
    }
    if (changed) await store.writeList(StoreKeys.posts, list);
  }

  /// Wipes saved data and loads fresh seed data with dates relative to now.
  Future<void> reset() async {
    for (final k in StoreKeys.all) {
      await store.remove(k);
    }
    await store.remove(StoreKeys.session);
    await seed();
  }

  Future<void> seed([DateTime? clock]) async {
    final now = clock ?? DateTime.now();
    DateTime ago({num hours = 0, num minutes = 0}) =>
        now.subtract(Duration(minutes: (hours * 60 + minutes).round()));

    // Users
    final users = <Map<String, dynamic>>[];
    for (final u in mapList(await _json('neighbours.json'))) {
      final vis = <String, dynamic>{
        'ageGroup': 'everyone',
        'gender': u['genderVisible'] == true ? 'everyone' : 'onlyMe',
        'level': 'everyone',
        'timeSlots': 'everyone',
      };
      users.add({
        ...u,
        'visibility': vis,
        'createdAt': ago(hours: 24 * 30).toIso8601String(),
      });
    }
    final userById = {for (final u in users) u['id'] as String: u};

    final photos = await _photoMap();

    // Posts
    final posts = <Map<String, dynamic>>[];
    for (final p in mapList(await _json('posts.json'))) {
      final m = Map<String, dynamic>.from(p);
      final author = userById[m['authorId']];
      m['communityId'] = author?['communityId'] ?? 'c_lakeside';
      if (m['startsAtOffset'] != null) {
        m['startsAt'] = resolveOffset(
          asMap(m['startsAtOffset']),
          now,
        ).toIso8601String();
        m.remove('startsAtOffset');
      }
      final photo = photos[(m['id'] as String).toLowerCase()];
      if (photo != null) m['photoPath'] = photo;
      m['createdAt'] = ago(
        hours: (m['createdAgoHours'] as num?) ?? 1,
      ).toIso8601String();
      m.remove('createdAgoHours');
      m['comments'] = mapList(m['comments'])
          .map(
            (c) => {
              'id': 'c_${m['id']}_${c['authorId']}',
              'authorId': c['authorId'],
              'text': c['text'],
              'createdAt': ago(
                hours: (c['agoHours'] as num?) ?? 1,
              ).toIso8601String(),
            },
          )
          .toList();
      posts.add(m);
    }

    // Challenges: every template is created once per community, scaled to
    // the community's size. Seeded neighbours are already taking part.
    final challenges = <Map<String, dynamic>>[];
    final comms = mapList(asMap(await _json('locations.json'))['communities']);
    for (final c in mapList(await _json('challenges.json'))) {
      for (final comm in comms) {
        final scale = (comm['scale'] as num?)?.toDouble() ?? 1.0;
        final cid = comm['id'] as String;
        final m = Map<String, dynamic>.from(c);
        m['id'] = '${c['id']}_$cid';
        m['communityId'] = cid;
        m['target'] = ((c['target'] as num) * scale).round();
        m['seedProgress'] = ((c['seedProgress'] as num) * scale).round();
        m['startsAt'] = resolveOffset(
          asMap(c['startsOffset']),
          now,
        ).toIso8601String();
        m['endsAt'] = resolveOffset(
          asMap(c['endsOffset']),
          now,
        ).toIso8601String();
        m.remove('startsOffset');
        m.remove('endsOffset');
        m['participantIds'] = users
            .where((u) => u['communityId'] == cid && u['isDemo'] != true)
            .take(4)
            .map((u) => u['id'])
            .toList();
        m['checkIns'] = <dynamic>[];
        challenges.add(m);
      }
    }

    // Conversations: seeded ones, plus a group chat for every meetup.
    final convs = <Map<String, dynamic>>[];
    for (final c in mapList(await _json('conversations.json'))) {
      final m = Map<String, dynamic>.from(c);
      m['messages'] = mapList(m['messages']).asMap().entries.map((e) {
        final msg = e.value;
        return {
          'id': 'm_${m['id']}_${e.key}',
          'senderId': msg['senderId'],
          'text': msg['text'],
          'isSystem': msg['isSystem'] ?? false,
          'createdAt': ago(
            minutes: (msg['agoMinutes'] as num?) ?? 5,
          ).toIso8601String(),
        };
      }).toList();
      convs.add(m);
    }
    for (final p in posts.where((p) => p['type'] == 'meetup')) {
      final has = convs.any((c) => c['sourcePostId'] == p['id']);
      if (has) continue;
      final author = userById[p['authorId']];
      convs.add({
        'id': 'conv_g_${p['id']}',
        'type': 'group',
        'memberIds': p['memberIds'],
        'sourcePostId': p['id'],
        'title': p['title'],
        'status': 'active',
        'messages': [
          {
            'id': 'm_conv_g_${p['id']}_0',
            'senderId': p['authorId'],
            'text': '${author?['nickname'] ?? 'Someone'} started this meetup',
            'isSystem': true,
            'createdAt': DateTime.parse(
              p['createdAt'] as String,
            ).toIso8601String(),
          },
        ],
      });
    }

    // Equipment loans
    final loans = <Map<String, dynamic>>[];
    for (final l in mapList(await _json('loans.json'))) {
      final m = Map<String, dynamic>.from(l);
      m['requestedAt'] = ago(
        hours: (m['requestedAgoHours'] as num?) ?? 5,
      ).toIso8601String();
      m.remove('requestedAgoHours');
      loans.add(m);
    }

    // Points history that adds up to each seeded user's points.
    final points = <Map<String, dynamic>>[];
    for (final u in users) {
      var left = (u['points'] as num?)?.toInt() ?? 0;
      var i = 0;
      while (left > 0) {
        const delta = 10;
        points.add({
          'id': 'pt_${u['id']}_$i',
          'userId': u['id'],
          'delta': delta,
          'label': 'Challenge check-in',
          'at': ago(hours: 12 + i * 30).toIso8601String(),
          'refType': 'seed',
        });
        left -= delta;
        i++;
      }
    }

    await store.writeList(StoreKeys.points, points);
    await store.writeList(StoreKeys.users, users);
    await store.writeList(StoreKeys.posts, posts);
    await store.writeList(StoreKeys.challenges, challenges);
    await store.writeList(StoreKeys.conversations, convs);
    await store.writeList(StoreKeys.loans, loans);
    await store.writeList(StoreKeys.logs, []);
    await store.setString(StoreKeys.seedVersion, _version);
  }

  /// Loads reference data (communities, locations, vouchers, codes).
  static Future<Map<String, dynamic>> loadLocations(AssetBundle b) async =>
      asMap(jsonDecode(await b.loadString('assets/seed/locations.json')));

  static Future<List<dynamic>> loadVouchers(AssetBundle b) async =>
      (jsonDecode(await b.loadString('assets/seed/vouchers.json')) as List);
}
