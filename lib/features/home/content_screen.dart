import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_iptv/core/models/stream_model.dart';
import 'package:flux_iptv/core/providers/streams_provider.dart';
import 'package:flux_iptv/features/home/widgets/stream_category_list_widget.dart';
import 'package:flux_iptv/features/home/widgets/netflix_movies_layout.dart';

class ContentScreen extends ConsumerWidget {
  final StreamType streamType;

  const ContentScreen({
    super.key,
    required this.streamType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsyncValue = ref.watch(streamsProvider);

    String title = 'Conteúdo';
    switch (streamType) {
      case StreamType.live:
        title = 'TV Ao Vivo';
        break;
      case StreamType.movie:
        title = 'Filmes';
        break;
      case StreamType.series:
        title = 'Séries';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF141414), // Dark background
      body: streamsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro ao carregar: $err', style: const TextStyle(color: Colors.white))),
        data: (streams) {
          if (streams.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum conteúdo encontrado para esta categoria.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final filteredStreams = streams.where((s) => s.streamType == streamType).toList();

          if (streamType == StreamType.live) {
            return StreamCategoryListWidget(items: filteredStreams, type: StreamType.live);
          } else {
            return NetflixMoviesLayout(items: filteredStreams);
          }
        },
      ),
    );
  }
}
