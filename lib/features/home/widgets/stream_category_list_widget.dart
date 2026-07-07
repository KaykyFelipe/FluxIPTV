import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flux_iptv/core/models/stream_model.dart';
import 'package:flux_iptv/core/providers/streams_provider.dart';

class StreamCategoryListWidget extends ConsumerStatefulWidget {
  final List<StreamModel> items;
  final StreamType type;

  const StreamCategoryListWidget({
    super.key,
    required this.items,
    required this.type,
  });

  @override
  ConsumerState<StreamCategoryListWidget> createState() => _StreamCategoryListWidgetState();
}

class _StreamCategoryListWidgetState extends ConsumerState<StreamCategoryListWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(child: Text('Nenhum conteúdo encontrado.'));
    }

    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      final filteredStreams = widget.items.where((s) => s.name.toLowerCase().contains(queryLower)).toList();

      return Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: filteredStreams.isEmpty
                ? const Center(child: Text('Nenhum resultado encontrado.'))
                : ListView.builder(
                    itemCount: filteredStreams.length,
                    itemBuilder: (context, index) {
                      final stream = filteredStreams[index];
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
                  ),
          ),
        ],
      );
    }

    final Map<String, List<StreamModel>> categories = {};
    for (final stream in widget.items) {
      if (stream.isFavorite) {
        if (!categories.containsKey('⭐ Favoritos')) {
          categories['⭐ Favoritos'] = [];
        }
        categories['⭐ Favoritos']!.add(stream);
      }

      final category = stream.groupTitle != null && stream.groupTitle!.trim().isNotEmpty
          ? stream.groupTitle!.trim()
          : 'Sem Categoria';
      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(stream);
    }

    final categoryNames = categories.keys.toList()..sort();
    if (categoryNames.contains('⭐ Favoritos')) {
      categoryNames.remove('⭐ Favoritos');
      categoryNames.insert(0, '⭐ Favoritos');
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            itemCount: categoryNames.length,
            itemBuilder: (context, index) {
              final categoryName = categoryNames[index];
              final categoryStreams = categories[categoryName]!;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: const Icon(Icons.folder, color: Colors.amber, size: 40),
                  title: Text(
                    categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${categoryStreams.length} itens'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(
                      '/category',
                      extra: {
                        'name': categoryName,
                        'type': widget.type,
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Pesquisar...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}
