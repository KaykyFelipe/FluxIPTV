import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flux_iptv/core/models/stream_model.dart';

class XtreamApi {
  static Future<Map<String, String>> _fetchCategories(String url) async {
    final Map<String, String> categoryMap = {};
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        if (jsonResponse is List) {
          for (var cat in jsonResponse) {
            final catId = cat['category_id']?.toString();
            final catName = cat['category_name']?.toString();
            if (catId != null && catName != null) {
              categoryMap[catId] = catName;
            }
          }
        }
      }
    } catch (e) {}
    return categoryMap;
  }

  static Future<List<StreamModel>> fetchAllStreams({
    required String domain,
    required String username,
    required String password,
  }) async {
    final cleanDomain = domain.endsWith('/') ? domain.substring(0, domain.length - 1) : domain;
    
    final liveUrl = '$cleanDomain/player_api.php?username=$username&password=$password&action=get_live_streams';
    final vodUrl = '$cleanDomain/player_api.php?username=$username&password=$password&action=get_vod_streams';
    final seriesUrl = '$cleanDomain/player_api.php?username=$username&password=$password&action=get_series';
    
    final liveCatMap = await _fetchCategories('$cleanDomain/player_api.php?username=$username&password=$password&action=get_live_categories');
    final vodCatMap = await _fetchCategories('$cleanDomain/player_api.php?username=$username&password=$password&action=get_vod_categories');
    final seriesCatMap = await _fetchCategories('$cleanDomain/player_api.php?username=$username&password=$password&action=get_series_categories');

    List<StreamModel> allStreams = [];

    // Live
    try {
      final response = await http.get(Uri.parse(liveUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        allStreams.addAll(jsonList.map((stream) {
          final streamId = stream['stream_id'];
          final videoUrl = '$cleanDomain/live/$username/$password/$streamId.ts';
          final categoryId = stream['category_id']?.toString();
          return StreamModel(
            name: stream['name']?.toString().trim() ?? 'Canal sem nome',
            url: videoUrl,
            tvgId: stream['epg_channel_id']?.toString(),
            tvgName: stream['name']?.toString(),
            tvgLogo: stream['stream_icon']?.toString(),
            groupTitle: stream['category_name']?.toString() ?? liveCatMap[categoryId] ?? 'Sem Categoria',
            streamType: StreamType.live,
          );
        }));
      }
    } catch (e) {}

    // VOD
    try {
      final response = await http.get(Uri.parse(vodUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        allStreams.addAll(jsonList.map((stream) {
          final streamId = stream['stream_id'];
          final ext = stream['container_extension'] ?? 'mp4';
          final videoUrl = '$cleanDomain/movie/$username/$password/$streamId.$ext';
          final categoryId = stream['category_id']?.toString();
          return StreamModel(
            name: stream['name']?.toString().trim() ?? 'Filme sem nome',
            url: videoUrl,
            tvgLogo: stream['stream_icon']?.toString(),
            groupTitle: stream['category_name']?.toString() ?? vodCatMap[categoryId] ?? 'Sem Categoria',
            streamType: StreamType.movie,
            streamId: int.tryParse(streamId.toString()),
          );
        }));
      }
    } catch (e) {}

    // Series
    try {
      final response = await http.get(Uri.parse(seriesUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        allStreams.addAll(jsonList.map((stream) {
          final streamId = stream['series_id'];
          final videoUrl = '$cleanDomain/series/$username/$password/$streamId'; 
          final categoryId = stream['category_id']?.toString();
          return StreamModel(
            name: stream['name']?.toString().trim() ?? 'Série sem nome',
            url: videoUrl,
            tvgLogo: stream['cover']?.toString(),
            groupTitle: stream['category_name']?.toString() ?? seriesCatMap[categoryId] ?? 'Sem Categoria',
            streamType: StreamType.series,
            streamId: int.tryParse(streamId.toString()),
          );
        }));
      }
    } catch (e) {}
    
    if (allStreams.isEmpty) {
      throw Exception('Falha ao conectar na API Xtream ou sem conteúdo retornado.');
    }

    return allStreams;
  }

  static Future<Map<String, dynamic>?> getVodInfo({
    required String domain,
    required String username,
    required String password,
    required int vodId,
  }) async {
    final cleanDomain = domain.endsWith('/') ? domain.substring(0, domain.length - 1) : domain;
    final url = '$cleanDomain/player_api.php?username=$username&password=$password&action=get_vod_info&vod_id=$vodId';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['info'] != null) {
          return data['info'];
        }
      }
    } catch (e) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getSeriesInfo({
    required String domain,
    required String username,
    required String password,
    required int seriesId,
  }) async {
    final cleanDomain = domain.endsWith('/') ? domain.substring(0, domain.length - 1) : domain;
    final url = '$cleanDomain/player_api.php?username=$username&password=$password&action=get_series_info&series_id=$seriesId';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['info'] != null) {
          return data;
        }
      }
    } catch (e) {}
    return null;
  }
}
