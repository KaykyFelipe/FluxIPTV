import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flux_iptv/core/parser/xtream_api.dart';
import 'package:flux_iptv/core/database/local_storage.dart';

class SeriesDetailsScreen extends StatefulWidget {
  final int seriesId;
  final String seriesName;

  const SeriesDetailsScreen({
    super.key,
    required this.seriesId,
    required this.seriesName,
  });

  @override
  State<SeriesDetailsScreen> createState() => _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends State<SeriesDetailsScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _info;
  Map<String, List<dynamic>> _episodes = {};
  String? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _fetchSeriesData();
  }

  Future<void> _fetchSeriesData() async {
    try {
      final creds = await CredentialsStorage.getCredentials();
      if (creds == null) throw Exception('Credenciais não encontradas.');

      final data = await XtreamApi.getSeriesInfo(
        domain: creds['domain']!,
        username: creds['user']!,
        password: creds['pass']!,
        seriesId: widget.seriesId,
      );

      if (data == null) throw Exception('Série não encontrada.');

      final info = data['info'] as Map<String, dynamic>?;
      final episodesData = data['episodes'];
      
      Map<String, List<dynamic>> parsedEpisodes = {};
      if (episodesData is Map) {
        for (var key in episodesData.keys) {
          parsedEpisodes[key.toString()] = List<dynamic>.from(episodesData[key] ?? []);
        }
      } else if (episodesData is List) {
        for (int i = 0; i < episodesData.length; i++) {
          if (episodesData[i] != null && episodesData[i] is List) {
            parsedEpisodes[(i + 1).toString()] = List<dynamic>.from(episodesData[i]);
          }
        }
      }

      if (mounted) {
        setState(() {
          _info = info;
          _episodes = parsedEpisodes;
          _selectedSeason = parsedEpisodes.keys.isNotEmpty ? parsedEpisodes.keys.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.seriesName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.seriesName)),
        body: Center(child: Text('Erro: $_error')),
      );
    }

    final coverUrl = _info?['cover']?.toString();
    final plot = _info?['plot']?.toString() ?? 'Sem sinopse.';
    final cast = _info?['cast']?.toString() ?? 'Desconhecido';
    
    final seasonKeys = _episodes.keys.toList();
    seasonKeys.sort((a, b) {
      final numA = int.tryParse(a) ?? 0;
      final numB = int.tryParse(b) ?? 0;
      if (numA != 0 && numB != 0) return numA.compareTo(numB);
      return a.compareTo(b);
    });

    final currentEpisodes = _selectedSeason != null ? _episodes[_selectedSeason!] : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.seriesName),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (coverUrl != null && coverUrl.isNotEmpty)
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                coverUrl,
                                height: 300,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.movie, size: 100),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          widget.seriesName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Elenco: $cast', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        Text(plot, style: const TextStyle(color: Colors.white70, height: 1.4)),
                        const SizedBox(height: 24),
                        if (seasonKeys.isNotEmpty)
                          DropdownButton<String>(
                            value: _selectedSeason,
                            isExpanded: true,
                            dropdownColor: Colors.grey[900],
                            underline: Container(height: 2, color: Colors.amber),
                            items: seasonKeys.map((season) {
                              return DropdownMenuItem(
                                value: season,
                                child: Text('Temporada $season', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSeason = val;
                                });
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                if (currentEpisodes == null || currentEpisodes.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('Nenhum episódio encontrado.')),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ep = currentEpisodes[index];
                        final title = ep['title']?.toString() ?? 'Episódio ${index + 1}';
                        final epNum = ep['episode_num']?.toString() ?? '${index + 1}';
                        final ext = ep['info']?['container_extension']?.toString() ?? ep['container_extension']?.toString() ?? 'mp4';
                        final epId = ep['id']?.toString() ?? '';
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: Card(
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(child: Text(epNum, style: const TextStyle(fontWeight: FontWeight.bold))),
                              ),
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.play_circle_fill, color: Colors.amber, size: 36),
                              onTap: () async {
                                if (epId.isEmpty) return;
                                final creds = await CredentialsStorage.getCredentials();
                                if (creds == null) return;
                                
                                final cleanDomain = creds['domain']!.endsWith('/') 
                                    ? creds['domain']!.substring(0, creds['domain']!.length - 1) 
                                    : creds['domain']!;
                                
                                final url = '$cleanDomain/series/${creds['user']}/${creds['pass']}/$epId.$ext';
                                
                                if (context.mounted) {
                                  context.push(
                                    '/player',
                                    extra: {
                                      'url': url,
                                      'name': '${widget.seriesName} - S$_selectedSeason E$epNum',
                                      'isLive': false,
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                      childCount: currentEpisodes.length,
                    ),
                  ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 300,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (coverUrl != null && coverUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          coverUrl,
                          width: 268,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.movie, size: 100),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      widget.seriesName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Elenco: $cast', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(plot, style: const TextStyle(color: Colors.white70, height: 1.4)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (seasonKeys.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: DropdownButton<String>(
                          value: _selectedSeason,
                          isExpanded: true,
                          dropdownColor: Colors.grey[900],
                          underline: Container(height: 2, color: Colors.amber),
                          items: seasonKeys.map((season) {
                            return DropdownMenuItem(
                              value: season,
                              child: Text('Temporada $season', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSeason = val;
                              });
                            }
                          },
                        ),
                      ),
                    Expanded(
                      child: currentEpisodes == null || currentEpisodes.isEmpty
                          ? const Center(child: Text('Nenhum episódio encontrado.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: currentEpisodes.length,
                              itemBuilder: (context, index) {
                                final ep = currentEpisodes[index];
                                final title = ep['title']?.toString() ?? 'Episódio ${index + 1}';
                                final epNum = ep['episode_num']?.toString() ?? '${index + 1}';
                                final ext = ep['info']?['container_extension']?.toString() ?? ep['container_extension']?.toString() ?? 'mp4';
                                final epId = ep['id']?.toString() ?? '';
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(child: Text(epNum, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    ),
                                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    trailing: const Icon(Icons.play_circle_fill, color: Colors.amber, size: 36),
                                    onTap: () async {
                                      if (epId.isEmpty) return;
                                      final creds = await CredentialsStorage.getCredentials();
                                      if (creds == null) return;
                                      
                                      final cleanDomain = creds['domain']!.endsWith('/') 
                                          ? creds['domain']!.substring(0, creds['domain']!.length - 1) 
                                          : creds['domain']!;
                                      
                                      final url = '$cleanDomain/series/${creds['user']}/${creds['pass']}/$epId.$ext';
                                      
                                      if (context.mounted) {
                                        context.push(
                                          '/player',
                                          extra: {
                                            'url': url,
                                            'name': '${widget.seriesName} - S$_selectedSeason E$epNum',
                                            'isLive': false,
                                          },
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
