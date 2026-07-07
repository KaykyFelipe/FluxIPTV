import 'package:flux_iptv/core/models/stream_model.dart';
import 'package:flux_iptv/core/parser/m3u_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageMock {
  static final List<StreamModel> _savedStreams = [];

  static Future<void> saveStreams(String m3uContent) async {
    final parsed = M3UParser.parse(m3uContent);
    _savedStreams.clear();
    _savedStreams.addAll(parsed);
  }

  static Future<void> saveStreamsFromList(List<StreamModel> streams) async {
    _savedStreams.clear();
    _savedStreams.addAll(streams);
  }

  static Future<List<StreamModel>> getStreams() async {
    // Simulate DB delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _savedStreams;
  }

  static Future<List<String>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final categories = _savedStreams
        .map((s) => s.groupTitle ?? 'Uncategorized')
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  static Future<void> clearStreams() async {
    _savedStreams.clear();
  }
}

class CredentialsStorage {
  static const _keyType = 'playlist_type'; // 'm3u' or 'xtream'
  static const _keyUrl = 'playlist_url';
  static const _keyDomain = 'xtream_domain';
  static const _keyUser = 'xtream_user';
  static const _keyPass = 'xtream_pass';

  static Future<void> saveM3uUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyType, 'm3u');
    await prefs.setString(_keyUrl, url);
  }

  static Future<void> saveXtream(String domain, String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyType, 'xtream');
    await prefs.setString(_keyDomain, domain);
    await prefs.setString(_keyUser, user);
    await prefs.setString(_keyPass, pass);
  }

  static Future<Map<String, String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString(_keyType);
    if (type == 'm3u') {
      final url = prefs.getString(_keyUrl);
      if (url != null) return {'type': 'm3u', 'url': url};
    } else if (type == 'xtream') {
      final domain = prefs.getString(_keyDomain);
      final user = prefs.getString(_keyUser);
      final pass = prefs.getString(_keyPass);
      if (domain != null && user != null && pass != null) {
        return {
          'type': 'xtream',
          'domain': domain,
          'user': user,
          'pass': pass,
        };
      }
    }
    return null;
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyType);
    await prefs.remove(_keyUrl);
    await prefs.remove(_keyDomain);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyPass);
  }
}

class FavoritesStorage {
  static const _keyFavorites = 'favorite_streams_urls';

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavorites) ?? [];
  }

  static Future<void> toggleFavorite(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_keyFavorites) ?? [];
    if (favs.contains(url)) {
      favs.remove(url);
    } else {
      favs.add(url);
    }
    await prefs.setStringList(_keyFavorites, favs);
  }
}
