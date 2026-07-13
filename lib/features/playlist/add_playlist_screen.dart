import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flux_iptv/core/providers/streams_provider.dart';
import 'package:flux_iptv/core/parser/xtream_api.dart';
import 'package:flux_iptv/core/database/local_storage.dart';
import 'package:flux_iptv/core/utils/responsive_layout.dart';

class AddPlaylistScreen extends ConsumerStatefulWidget {
  const AddPlaylistScreen({super.key});

  @override
  ConsumerState<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends ConsumerState<AddPlaylistScreen> {
  // M3U Controllers
  final _m3uUrlController = TextEditingController();
  final _m3uNameController = TextEditingController();
  
  // Xtream Controllers
  final _xtreamDomainController = TextEditingController();
  final _xtreamUserController = TextEditingController();
  final _xtreamPassController = TextEditingController();

  bool _isLoading = false;
  Map<String, String>? _currentCreds;
  String _deviceMac = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _loadCurrentPlaylist();
    _loadDeviceMac();
  }

  Future<void> _loadDeviceMac() async {
    final mac = await SettingsStorage.getDeviceMac();
    if (mounted) {
      setState(() {
        _deviceMac = mac;
      });
    }
  }

  Future<void> _loadCurrentPlaylist() async {
    final creds = await CredentialsStorage.getCredentials();
    if (mounted) {
      setState(() {
        _currentCreds = creds;
      });
    }
  }

  Future<void> _removePlaylist() async {
    await ref.read(streamsProvider.notifier).clear();
    if (mounted) {
      setState(() {
        _currentCreds = null;
      });
      _showSnack('Playlist removida com sucesso!');
    }
  }

  @override
  void dispose() {
    _m3uUrlController.dispose();
    _m3uNameController.dispose();
    _xtreamDomainController.dispose();
    _xtreamUserController.dispose();
    _xtreamPassController.dispose();
    super.dispose();
  }

  Future<void> _fetchM3U() async {
    final url = _m3uUrlController.text.trim();
    if (url.isEmpty) {
      _showSnack('Por favor, insira uma URL M3U válida.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        await ref.read(streamsProvider.notifier).saveStreams(response.body);
        await CredentialsStorage.saveM3uUrl(url);
        _successAndPop();
      } else {
        throw Exception('Erro na requisição: ${response.statusCode}');
      }
    } catch (e) {
      _showSnack('Erro ao baixar M3U: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchXtream() async {
    final domain = _xtreamDomainController.text.trim();
    final user = _xtreamUserController.text.trim();
    final pass = _xtreamPassController.text.trim();

    if (domain.isEmpty || user.isEmpty || pass.isEmpty) {
      _showSnack('Preencha todos os campos do Xtream Codes.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final streams = await XtreamApi.fetchAllStreams(
        domain: domain,
        username: user,
        password: pass,
      );
      
      await ref.read(streamsProvider.notifier).saveStreamsFromList(streams);
      await CredentialsStorage.saveXtream(domain, user, pass);
      _successAndPop();
    } catch (e) {
      _showSnack('Erro Xtream: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _successAndPop() {
    if (mounted) {
      _showSnack('Playlist salva com sucesso!');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTV = ResponsiveLayout.isDesktopOrTV(context);

    if (isDesktopOrTV && _currentCreds == null) {
      return _buildTvMacScreen();
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Adicionar Playlist'),
          bottom: isDesktopOrTV && _currentCreds != null ? null : const TabBar(
            tabs: [
              Tab(text: 'Xtream Codes'),
              Tab(text: 'Link M3U'),
            ],
          ),
        ),
        body: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Conectando e baixando canais...\nIsso pode demorar um pouco.', textAlign: TextAlign.center)
                ],
              ),
            )
          : Column(
              children: [
                if (_currentCreds != null) _buildCurrentPlaylistCard(),
                if (_currentCreds == null)
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildXtreamTab(),
                        _buildM3uTab(),
                      ],
                    ),
                  ),
              ],
            ),
      ),
    );
  }

  Widget _buildTvMacScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        title: const Text('Adicionar Playlist (TV)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text(
                'Sincronize sua Playlist via Web',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Acesse www.fluxiptv.com no seu celular ou computador.',
                style: TextStyle(fontSize: 18, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '2. Insira o Código MAC abaixo para vincular sua assinatura:',
                style: TextStyle(fontSize: 18, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Text(
                  _deviceMac,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 4),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                   // SIMULATION FOR TESTING WITHOUT BACKEND
                   setState(() {
                     _xtreamDomainController.text = 'http://tv.com:8080';
                     _xtreamUserController.text = 'teste_tv';
                     _xtreamPassController.text = '123456';
                   });
                   _fetchXtream();
                },
                icon: const Icon(Icons.sync),
                label: const Text('Verificar Sincronização (Simular)', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlaylistCard() {
    final type = _currentCreds!['type'];
    final info = type == 'm3u' 
        ? _currentCreds!['url'] ?? ''
        : '${_currentCreds!['domain']} (${_currentCreds!['user']})';
        
    return Card(
      margin: const EdgeInsets.all(16.0),
      color: Colors.blueGrey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.playlist_play, size: 40, color: Colors.amber),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Playlist Atual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(info, style: const TextStyle(color: Colors.white70)),
                  Text('Tipo: ${type?.toUpperCase()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Remover Playlist',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remover Playlist?'),
                    content: const Text('Isso irá apagar todos os canais e favoritos locais. Tem certeza?'),
                    actions: [
                      TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => ctx.pop(true), child: const Text('Remover', style: TextStyle(color: Colors.red))),
                    ],
                  )
                );
                if (confirm == true) {
                  await _removePlaylist();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXtreamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Conecte-se usando as credenciais fornecidas pelo seu provedor (Recomendado).',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xtreamDomainController,
            decoration: const InputDecoration(
              labelText: 'URL do Servidor (ex: http://tv.com:8080)',
              prefixIcon: Icon(Icons.dns),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xtreamUserController,
            decoration: const InputDecoration(
              labelText: 'Usuário',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xtreamPassController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Senha',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _fetchXtream,
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildM3uTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _m3uNameController,
            decoration: const InputDecoration(
              labelText: 'Nome da Lista (Opcional)',
              prefixIcon: Icon(Icons.label),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _m3uUrlController,
            decoration: const InputDecoration(
              labelText: 'URL da Playlist (M3U/M3U8)',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _fetchM3U,
            child: const Text('Salvar M3U'),
          ),
        ],
      ),
    );
  }
}
