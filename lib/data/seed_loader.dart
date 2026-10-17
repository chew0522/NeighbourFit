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

  static const _version = '4';

  Future<dynamic> _json(String name) async =>
      jsonDecode(await bundle.loadString('assets/seed/$name'));

  Future<void> ensureSeeded() async {
    if (store.getString(StoreKeys.seedVersion) == _version) return;
    await seed();
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
    DateTime ago({num hours = 0, num minutes = 0}) => now.subtract(
        Duration(minutes: (hours * 60 + minutes).round()));

    // Users
    final users = <Map<String, dynamic>>[];
    for (final u in mapList(await _json('neighbours.json'))) {
      final vis = <String, dynamic>{
        'ageGroup': 'community',
        'gender': u['genderVisible'] == true ? 'community' : 'onlyMe',
        'level': 'community',
        'timeSlots': 'community',
      };
      users.add({
        ...u,
        'visibility': vis,
        'createdAt': ago(hours: 24 * 30).toIso8601String(),
      });
    }
    final userById = {for (final u in users) u['id'] as String: u};

    // Posts
    final posts = <Map<String, dynamic>>[];
    for (final p in mapList(await _json('posts.json'))) {
      final m = Map<String, dynamic>.from(p);
      final author = userById[m['authorId']];
      m['communityId'] = author?['communityId'] ?? 'c_lakeside';
      if (m['startsAtOffset'] != null) {
        m['startsAt'] =
            resolveOffset(asMap(m['startsAtOffset']), now).toIso8601String();
        m.remove('startsAtOffset');
      }
      m['createdAt'] =
          ago(hours: (m['createdAgoHours'] as num?) ?? 1).toIso8601String();
      m.remove('createdAgoHours');
      m['comments'] = mapList(m['comments'])
          .map((c) => {
                'id': 'c_${m['id']}_${c['authorId']}',
                'authorId': c['authorId'],
                'text': c['text'],
                'createdAt':
                    ago(hours: (c['agoHours'] as num?) ?? 1).toIso8601String(),
              })
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
        m['startsAt'] = resolveOffset(asMap(c['startsOffset']), now).toIso8601String();
        m['endsAt'] = resolveOffset(asMap(c['endsOffset']), now).toIso8601String();
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
          'createdAt':
              ago(minutes: (msg['agoMinutes'] as num?) ?? 5).toIso8601String(),
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
            'createdAt': DateTime.parse(p['createdAt'] as String).toIso8601String(),
          }
        ],
      });
    }

    // Equipment loans
    final loans = <Map<String, dynamic>>[];
    for (final l in mapList(await _json('loans.json'))) {
      final m = Map<String, dynamic>.from(l);
      m['requestedAt'] = ago(hours: (m['requestedAgoHours'] as num?) ?? 5).toIso8601String();
      m.remove('requestedAgoHours');
      loans.add(m);
    }

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
