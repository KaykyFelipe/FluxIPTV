import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_iptv/core/models/stream_model.dart';
import 'package:flux_iptv/core/database/local_storage.dart';

import 'package:http/http.dart' as http;
import 'package:flux_iptv/core/parser/xtream_api.dart';

final streamsProvider = AsyncNotifierProvider<StreamsNotifier, List<StreamModel>>(() {
  return StreamsNotifier();
});

class StreamsNotifier extends AsyncNotifier<List<StreamModel>> {
  @override
  Future<List<StreamModel>> build() async {
    final creds = await CredentialsStorage.getCredentials();
    if (creds != null) {
      if (creds['type'] == 'm3u') {
        try {
          final res = await http.get(Uri.parse(creds['url']!));
          if (res.statusCode == 200) {
            await LocalStorageMock.saveStreams(res.body);
          }
        } catch (e) {}
      } else if (creds['type'] == 'xtream') {
        try {
          final streams = await XtreamApi.fetchAllStreams(
            domain: creds['domain']!,
            username: creds['user']!,
            password: creds['pass']!
          );
          await LocalStorageMock.saveStreamsFromList(streams);
        } catch (e) {}
      }
    }
    return _fetchStreams();
  }

  Future<List<StreamModel>> _fetchStreams() async {
    final rawStreams = await LocalStorageMock.getStreams();
    final favs = await FavoritesStorage.getFavorites();
    final favSet = favs.toSet();

    return rawStreams.map((s) {
      if (favSet.contains(s.url)) {
        return s.copyWith(isFavorite: true);
      }
      return s;
    }).toList();
  }

  Future<void> toggleFavorite(String url) async {
    await FavoritesStorage.toggleFavorite(url);
    if (state.hasValue) {
      final currentList = state.value!;
      final updatedList = currentList.map((s) {
        if (s.url == url) {
          return s.copyWith(isFavorite: !s.isFavorite);
        }
        return s;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
  }

  Future<void> saveStreams(String m3uContent) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await LocalStorageMock.saveStreams(m3uContent);
      return _fetchStreams();
    });
  }

  Future<void> saveStreamsFromList(List<StreamModel> streams) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await LocalStorageMock.saveStreamsFromList(streams);
      return _fetchStreams();
    });
  }

  Future<void> clear() async {
    await CredentialsStorage.clearCredentials();
    await LocalStorageMock.clearStreams();
    state = const AsyncValue.data([]);
  }
}
