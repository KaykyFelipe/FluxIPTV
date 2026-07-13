import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flux_iptv/core/models/stream_model.dart';
import 'package:flux_iptv/core/providers/streams_provider.dart';
import 'package:flux_iptv/core/utils/responsive_layout.dart';

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

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveLayout.getCrossAxisCount(context, mobile: 1, tablet: 2, desktop: 3),
              childAspectRatio: ResponsiveLayout.isMobile(context) ? 4.5 : 3.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: displayStreams.length,
            itemBuilder: (context, index) {
              final stream = displayStreams[index];
              return _FocusableListItem(
                leading: stream.tvgLogo != null && stream.tvgLogo!.isNotEmpty
                    ? Image.network(
                        stream.tvgLogo!,
                        width: 50,
                        height: 50,
                        errorBuilder: (_, __, ___) => const Icon(Icons.tv),
                      )
                    : const Icon(Icons.tv),
                title: stream.name,
                subtitle: stream.groupTitle ?? 'Sem Categoria',
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

class _FocusableListItem extends StatefulWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _FocusableListItem({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  State<_FocusableListItem> createState() => _FocusableListItemState();
}

class _FocusableListItemState extends State<_FocusableListItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: _isFocused ? 8 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: 2.0,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Center(
              child: ListTile(
                leading: widget.leading,
                title: Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: widget.trailing,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
