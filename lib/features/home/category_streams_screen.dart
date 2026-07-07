import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flux_iptv/core/models/stream_model.dart';
import 'package:flux_iptv/core/providers/streams_provider.dart';

class CategoryStreamsScreen extends ConsumerWidget {
  final String categoryName;
  final StreamType streamType;

  const CategoryStreamsScreen({
    super.key,
    required this.categoryName,
    required this.streamType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsync = ref.watch(streamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: streamsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        data: (allStreams) {
          List<StreamModel> displayStreams = [];
          
          if (categoryName == '⭐ Favoritos') {
            displayStreams = allStreams.where((s) => s.streamType == streamType && s.isFavorite).toList();
          } else {
            displayStreams = allStreams.where((s) {
              final cat = s.groupTitle != null && s.groupTitle!.trim().isNotEmpty 
                  ? s.groupTitle!.trim() 
                  : 'Sem Categoria';
              return s.streamType == streamType && cat == categoryName;
            }).toList();
          }

          if (displayStreams.isEmpty) {
            return const Center(child: Text('Nenhum conteúdo encontrado.'));
          }

          return ListView.builder(
            itemCount: displayStreams.length,
            itemBuilder: (context, index) {
              final stream = displayStreams[index];
              return ListTile(
                leading: stream.tvgLogo != null && stream.tvgLogo!.isNotEmpty
                    ? Image.network(
                        stream.tvgLogo!,
                        width: 50,
                        height: 50,
                        errorBuilder: (_, __, ___) => const Icon(Icons.tv),
                      )
                    : const Icon(Icons.tv),
                title: Text(stream.name),
                subtitle: Text(stream.groupTitle ?? 'Sem Categoria'),
                trailing: IconButton(
                  icon: Icon(
                    stream.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: stream.isFavorite ? Colors.red : null,
                  ),
                  onPressed: () {
                    ref.read(streamsProvider.notifier).toggleFavorite(stream.url);
                  },
                ),
                onTap: () {
                  context.push(
                    '/player',
                    extra: {
                      'url': stream.url,
                      'name': stream.name,
                      'isLive': stream.streamType == StreamType.live,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
