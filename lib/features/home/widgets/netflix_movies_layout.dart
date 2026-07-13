import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_iptv/core/models/stream_model.dart';
import 'package:flux_iptv/core/providers/streams_provider.dart';
import 'package:flux_iptv/core/database/local_storage.dart';
import 'package:flux_iptv/core/parser/xtream_api.dart';
import 'package:flux_iptv/core/utils/responsive_layout.dart';

class NetflixMoviesLayout extends ConsumerStatefulWidget {
  final List<StreamModel> items;

  const NetflixMoviesLayout({super.key, required this.items});

  @override
  ConsumerState<NetflixMoviesLayout> createState() => _NetflixMoviesLayoutState();
}

class _NetflixMoviesLayoutState extends ConsumerState<NetflixMoviesLayout> {
  final ValueNotifier<StreamModel?> _focusedMovieNotifier = ValueNotifier(null);
  Map<String, dynamic>? _vodInfo;
  Timer? _debounceTimer;
  Timer? _scrollDebounce;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  bool _searchFocused = false;
  bool _filterFocused = false;

  late Map<String, List<StreamModel>> _categories;
  late List<String> _categoryNames;
  final Map<String, StreamModel> _lastFocusedPerCategory = {};

  @override
  void initState() {
    super.initState();
    _focusedMovieNotifier.addListener(_onFocusedMovieChanged);
    _buildCategories();
  }

  @override
  void didUpdateWidget(covariant NetflixMoviesLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _buildCategories();
    }
  }

  void _buildCategories() {
    _categories = {};
    for (final stream in widget.items) {
      if (stream.isFavorite) {
        _categories.putIfAbsent('⭐ Favoritos', () => []).add(stream);
      }
      final cat = stream.groupTitle != null && stream.groupTitle!.trim().isNotEmpty 
          ? stream.groupTitle!.trim() 
          : 'Sem Categoria';
      _categories.putIfAbsent(cat, () => []).add(stream);
    }

    _categoryNames = _categories.keys.toList()..sort();
    if (_categoryNames.contains('⭐ Favoritos')) {
      _categoryNames.remove('⭐ Favoritos');
      _categoryNames.insert(0, '⭐ Favoritos');
    }

    if (widget.items.isNotEmpty && _focusedMovieNotifier.value == null) {
      final firstCat = _categoryNames.first;
      final firstMovie = _categories[firstCat]?.first;
      if (firstMovie != null) {
        _lastFocusedPerCategory[firstCat] = firstMovie;
        _focusedMovieNotifier.value = firstMovie;
      }
    }
  }

  void _onFocusedMovieChanged() {
    setState(() {
      _vodInfo = null;
    });
    _fetchVodInfoDebounced(_focusedMovieNotifier.value);
  }

  void _onMovieFocused(StreamModel movie, String catName) {
    _lastFocusedPerCategory[catName] = movie;
    _scrollDebounce?.cancel();
    if (_focusedMovieNotifier.value?.url == movie.url) return;
    _focusedMovieNotifier.value = movie;
  }

  void _onMovieScrolled(StreamModel movie, String catName) {
    _lastFocusedPerCategory[catName] = movie;
    if (_focusedMovieNotifier.value?.url == movie.url) return;
    
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        _focusedMovieNotifier.value = movie;
      }
    });
  }

  void _fetchVodInfoDebounced(StreamModel? movie) {
    if (movie == null) return;
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (movie.streamId == null) return;
      final creds = await CredentialsStorage.getCredentials();
      if (creds != null && creds['type'] == 'xtream') {
        Map<String, dynamic>? info;
        if (movie.streamType == StreamType.series) {
          final res = await XtreamApi.getSeriesInfo(
            domain: creds['domain']!,
            username: creds['user']!,
            password: creds['pass']!,
            seriesId: movie.streamId!,
          );
          info = res?['info'];
        } else {
          info = await XtreamApi.getVodInfo(
            domain: creds['domain']!,
            username: creds['user']!,
            password: creds['pass']!,
            vodId: movie.streamId!,
          );
        }

        if (mounted && _focusedMovieNotifier.value?.url == movie.url) {
          setState(() {
            _vodInfo = info;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusedMovieNotifier.removeListener(_onFocusedMovieChanged);
    _focusedMovieNotifier.dispose();
    _debounceTimer?.cancel();
    _scrollDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(child: Text('Nenhum título encontrado.'));
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: (_searchQuery.isNotEmpty || _selectedCategory != null)
              ? _buildSearchResults()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = ResponsiveLayout.isMobile(context);
                    final isTablet = ResponsiveLayout.isTablet(context);
                    return Column(
                      children: [
                        // Hero Section (Responsive height)
                        SizedBox(
                          height: constraints.maxHeight * (isMobile ? 0.45 : (isTablet ? 0.50 : 0.60)),
                          child: _buildHeroSection(),
                        ),
                        // Rails Section
                        Expanded(
                          child: _buildRails(isMobile, isTablet),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Filtrar por Categoria',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: _categoryNames.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      title: const Text('Todas as Categorias', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      trailing: _selectedCategory == null ? const Icon(Icons.check, color: Colors.amber) : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = null;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }
                  final cat = _categoryNames[index - 1];
                  return ListTile(
                    title: Text(cat, style: const TextStyle(color: Colors.white70)),
                    trailing: _selectedCategory == cat ? const Icon(Icons.check, color: Colors.amber) : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onFocusChange: (focused) => setState(() => _searchFocused = focused),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _searchFocused ? Colors.white : Colors.transparent,
                    width: _searchFocused ? 2 : 0,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
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
              ),
            ),
          ),
          const SizedBox(width: 8),
          Focus(
            onFocusChange: (focused) => setState(() => _filterFocused = focused),
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                _showCategoryFilter();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: _showCategoryFilter,
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedCategory != null ? Colors.amber.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _filterFocused 
                        ? Colors.white 
                        : (_selectedCategory != null ? Colors.amber : Colors.white24),
                    width: _filterFocused ? 3 : 1,
                  ),
                  boxShadow: _filterFocused
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: _filterFocused 
                        ? Colors.white 
                        : (_selectedCategory != null ? Colors.amber : Colors.white),
                  ),
                  onPressed: _showCategoryFilter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return ValueListenableBuilder<StreamModel?>(
      valueListenable: _focusedMovieNotifier,
      builder: (context, focusedMovie, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: focusedMovie == null
              ? const SizedBox.shrink()
              : Container(
                  key: ValueKey(focusedMovie.url),
                  decoration: BoxDecoration(
                    image: focusedMovie.tvgLogo != null && focusedMovie.tvgLogo!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(focusedMovie.tvgLogo!),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          )
                        : null,
                    color: Colors.black,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black,
                          Colors.black87,
                          Colors.black54,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3, 0.6, 1.0],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'FLUXIPTV ORIGINAL',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          focusedMovie.name,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              '98% Relevante',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _vodInfo?['releasedate']?.toString() ?? '2023',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _vodInfo?['duration']?.toString() ?? '1h 45m',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white54),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('HD', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 500,
                          child: Text(
                            _vodInfo?['plot']?.toString() ?? 'Acompanhe esta incrível história cheia de emoção e aventura no FluxIPTV. (Sinopse Indisponível)',
                            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Elenco: ${_vodInfo?['cast']?.toString() ?? 'Indisponível'}\n'
                          'Gênero: ${_vodInfo?['genre']?.toString() ?? focusedMovie.groupTitle ?? 'Geral'}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildRails(bool isMobile, bool isTablet) {
    final double railHeight = isMobile ? 150 : (isTablet ? 180 : 220);
    final double itemWidth = isMobile ? 250 : (isTablet ? 300 : 350);

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is ScrollUpdateNotification && scrollInfo.metrics.axis == Axis.vertical) {
          final rowIndex = (scrollInfo.metrics.pixels / (railHeight + 50)).clamp(0, _categoryNames.length - 1).toInt();
          final catName = _categoryNames[rowIndex];
          final streams = _categories[catName]!;
          final movieToFocus = _lastFocusedPerCategory[catName] ?? streams.first;
          _onMovieScrolled(movieToFocus, catName);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        itemCount: _categoryNames.length,
        itemBuilder: (context, index) {
          final catName = _categoryNames[index];
          final streams = _categories[catName]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text(
                  catName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                height: railHeight,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo is ScrollUpdateNotification && scrollInfo.metrics.axis == Axis.horizontal) {
                      final itemIndex = (scrollInfo.metrics.pixels / (itemWidth + 16)).clamp(0, streams.length - 1).toInt();
                      _onMovieScrolled(streams[itemIndex], catName);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: streams.length,
                    itemBuilder: (context, idx) {
                      final stream = streams[idx];
                      return MovieThumbnail(
                        movie: stream,
                        focusedNotifier: _focusedMovieNotifier,
                        width: itemWidth,
                        onFocus: () => _onMovieFocused(stream, catName),
                        onTap: () {
                          if (stream.streamType == StreamType.series) {
                            final encodedName = Uri.encodeComponent(stream.name);
                            context.push('/series_details?id=${stream.streamId}&name=$encodedName');
                          } else {
                            context.push(
                              '/player',
                              extra: {
                                'url': stream.url,
                                'name': stream.name,
                                'isLive': false,
                              },
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    final queryLower = _searchQuery.toLowerCase();
    
    final filteredStreams = widget.items.where((s) {
      final matchesQuery = queryLower.isEmpty || s.name.toLowerCase().contains(queryLower);
      
      final streamCat = s.groupTitle != null && s.groupTitle!.trim().isNotEmpty 
          ? s.groupTitle!.trim() 
          : 'Sem Categoria';
      final matchesCategory = _selectedCategory == null || 
                              (_selectedCategory == '⭐ Favoritos' ? s.isFavorite : streamCat == _selectedCategory);
                              
      return matchesQuery && matchesCategory;
    }).toList();

    if (filteredStreams.isEmpty) {
      return const Center(child: Text('Nenhum título encontrado.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.getCrossAxisCount(context, mobile: 2, tablet: 4, desktop: 6),
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
      ),
      itemCount: filteredStreams.length,
      itemBuilder: (context, index) {
        final stream = filteredStreams[index];
        return MovieThumbnail(
          movie: stream,
          focusedNotifier: _focusedMovieNotifier,
          showTitleBelow: true,
          onFocus: () {},
          onTap: () {
            if (stream.streamType == StreamType.series) {
              final encodedName = Uri.encodeComponent(stream.name);
              context.push('/series_details?id=${stream.streamId}&name=$encodedName');
            } else {
              context.push(
                '/player',
                extra: {
                  'url': stream.url,
                  'name': stream.name,
                  'isLive': false,
                },
              );
            }
          },
        );
      },
    );
  }
}

class MovieThumbnail extends StatefulWidget {
  final StreamModel movie;
  final ValueNotifier<StreamModel?> focusedNotifier;
  final bool showTitleBelow;
  final double width;
  final VoidCallback onFocus;
  final VoidCallback onTap;

  const MovieThumbnail({
    super.key,
    required this.movie,
    required this.focusedNotifier,
    this.showTitleBelow = false,
    this.width = 250,
    required this.onFocus,
    required this.onTap,
  });

  @override
  State<MovieThumbnail> createState() => _MovieThumbnailState();
}

class _MovieThumbnailState extends State<MovieThumbnail> {
  bool _isNativeFocused = false;
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.focusedNotifier.value?.url == widget.movie.url;
    widget.focusedNotifier.addListener(_onNotifierChanged);
  }

  @override
  void didUpdateWidget(covariant MovieThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedNotifier != widget.focusedNotifier) {
      oldWidget.focusedNotifier.removeListener(_onNotifierChanged);
      widget.focusedNotifier.addListener(_onNotifierChanged);
    }
    _isSelected = widget.focusedNotifier.value?.url == widget.movie.url;
  }

  void _onNotifierChanged() {
    final isNowSelected = widget.focusedNotifier.value?.url == widget.movie.url;
    if (_isSelected != isNowSelected) {
      if (mounted) {
        setState(() {
          _isSelected = isNowSelected;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.focusedNotifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showHighlight = _isNativeFocused || _isSelected;

    final imageContainer = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.showTitleBelow ? double.infinity : widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: showHighlight ? Colors.white : Colors.transparent,
          width: 3.0,
        ),
        boxShadow: showHighlight
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 10),
                )
              ]
            : [],
        image: widget.movie.tvgLogo != null && widget.movie.tvgLogo!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(widget.movie.tvgLogo!),
                fit: BoxFit.cover,
              )
            : null,
        color: Colors.grey.shade900,
      ),
      child: widget.movie.tvgLogo == null || widget.movie.tvgLogo!.isEmpty
          ? Center(
              child: Text(
                widget.movie.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            )
          : const SizedBox.shrink(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Focus(
        onFocusChange: (focused) {
          setState(() {
            _isNativeFocused = focused;
          });
          if (focused) {
            widget.onFocus();
          }
        },
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
            widget.onFocus();
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () {
            widget.onFocus();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: showHighlight ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: widget.showTitleBelow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: imageContainer),
                      const SizedBox(height: 8),
                      Text(
                        widget.movie.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : imageContainer,
          ),
        ),
      ),
    );
  }
}
