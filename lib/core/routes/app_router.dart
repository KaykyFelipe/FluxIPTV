import 'package:go_router/go_router.dart';
import 'package:flux_iptv/features/home/home_screen.dart';
import 'package:flux_iptv/features/home/category_streams_screen.dart';
import 'package:flux_iptv/features/playlist/add_playlist_screen.dart';
import 'package:flux_iptv/features/player/player_screen.dart';
import 'package:flux_iptv/features/series/series_details_screen.dart';
import 'package:flux_iptv/features/home/content_screen.dart';
import 'package:flux_iptv/core/models/stream_model.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/category',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final name = extra?['name'] as String? ?? 'Categoria';
        final type = extra?['type'] as StreamType? ?? StreamType.live;
        return CategoryStreamsScreen(categoryName: name, streamType: type);
      },
    ),
    GoRoute(
      path: '/content',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final type = extra?['type'] as StreamType? ?? StreamType.live;
        return ContentScreen(streamType: type);
      },
    ),
    GoRoute(
      path: '/add_playlist',
      builder: (context, state) => const AddPlaylistScreen(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final url = extra?['url'] as String? ?? state.uri.queryParameters['url'] ?? '';
        final name = extra?['name'] as String? ?? state.uri.queryParameters['name'] ?? 'Canal';
        
        bool isLive = true;
        if (extra != null && extra.containsKey('isLive')) {
          isLive = extra['isLive'] as bool;
        } else if (state.uri.queryParameters.containsKey('isLive')) {
          isLive = state.uri.queryParameters['isLive'] == 'true';
        }
        
        return PlayerScreen(streamUrl: url, channelName: name, isLive: isLive);
      },
    ),
    GoRoute(
      path: '/series_details',
      builder: (context, state) {
        final id = int.tryParse(state.uri.queryParameters['id'] ?? '0') ?? 0;
        final name = state.uri.queryParameters['name'] ?? 'Série';
        return SeriesDetailsScreen(seriesId: id, seriesName: name);
      },
    ),
  ],
);
