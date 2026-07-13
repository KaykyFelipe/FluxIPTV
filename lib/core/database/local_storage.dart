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

class SettingsStorage {
  static const _keyHwDecoding = 'setting_hw_decoding';
  static const _keyBufferSize = 'setting_buffer_size'; // 0: Small, 1: Medium, 2: Large
  static const _keyAutoPlay = 'setting_auto_play';
  static const _keyParentalPin = 'setting_parental_pin';
  static const _keyEpgTimeShift = 'setting_epg_time_shift';
  static const _keyTimeFormat24h = 'setting_time_format_24h';
  static const _keyDeviceMac = 'device_mac_address';

  static Future<String> getDeviceMac() async {
    final prefs = await SharedPreferences.getInstance();
    String? mac = prefs.getString(_keyDeviceMac);
    if (mac == null || mac.isEmpty) {
      // Generate a random 6-character hex/alphanumeric "MAC" or "Device Key"
      const chars = '0123456789ABCDEF';
      final rnd = DateTime.now().millisecondsSinceEpoch;
      mac = 'FLUX-${(rnd % 1000000).toString().padLeft(6, '0')}';
      await prefs.setString(_keyDeviceMac, mac);
    }
    return mac;
  }

  static Future<Map<String, dynamic>> getAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hwDecoding': prefs.getBool(_keyHwDecoding) ?? true,
      'bufferSize': prefs.getInt(_keyBufferSize) ?? 1,
      'autoPlay': prefs.getBool(_keyAutoPlay) ?? false,
      'parentalPin': prefs.getString(_keyParentalPin) ?? '',
      'epgTimeShift': prefs.getInt(_keyEpgTimeShift) ?? 0,
      'timeFormat24h': prefs.getBool(_keyTimeFormat24h) ?? true,
    };
  }

  static Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  // Helper getters for keys
  static String get keyHwDecoding => _keyHwDecoding;
  static String get keyBufferSize => _keyBufferSize;
  static String get keyAutoPlay => _keyAutoPlay;
  static String get keyParentalPin => _keyParentalPin;
  static String get keyEpgTimeShift => _keyEpgTimeShift;
  static String get keyTimeFormat24h => _keyTimeFormat24h;
}
