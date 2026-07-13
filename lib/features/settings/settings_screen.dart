import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flux_iptv/core/providers/settings_provider.dart';
import 'package:flux_iptv/core/providers/streams_provider.dart';
import 'package:flux_iptv/core/database/local_storage.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _showPinDialog(BuildContext context, String currentPin) {
    _pinController.text = currentPin;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Definir PIN Parental'),
          content: TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(
              hintText: 'Digite 4 números (ex: 1234)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).updateParentalPin(_pinController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN atualizado com sucesso!')),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _handleDisconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar?'),
        content: const Text('Isso removerá a sua playlist atual e as credenciais salvas. Você precisará fazer login novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CredentialsStorage.clearCredentials();
      await LocalStorageMock.clearStreams();
      if (mounted) {
        context.go('/add_playlist');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section: Playlist
          _buildSectionTitle('Contas e Playlists'),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Sincronizar Lista (Atualizar)'),
                subtitle: const Text('Baixa os filmes e canais mais recentes do servidor.'),
                onTap: () {
                  ref.invalidate(streamsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Atualizando lista de canais...')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Desconectar (Sair)', style: TextStyle(color: Colors.redAccent)),
                subtitle: const Text('Remove as credenciais salvas deste dispositivo.'),
                onTap: _handleDisconnect,
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Section: Player
          _buildSectionTitle('Player de Vídeo'),
          _buildCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.memory),
                title: const Text('Aceleração de Hardware (HW)'),
                subtitle: const Text('Desative se os canais estiverem travando ou sem áudio.'),
                value: settings.hwDecoding,
                onChanged: (val) => notifier.updateHwDecoding(val),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.network_ping),
                title: const Text('Tamanho do Buffer de Rede'),
                subtitle: Text(_getBufferName(settings.bufferSize)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final newSize = await showDialog<int>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Tamanho do Buffer'),
                      children: [
                        SimpleDialogOption(onPressed: () => Navigator.pop(context, 0), child: const Text('Pequeno (Rápido para carregar)')),
                        SimpleDialogOption(onPressed: () => Navigator.pop(context, 1), child: const Text('Médio (Recomendado)')),
                        SimpleDialogOption(onPressed: () => Navigator.pop(context, 2), child: const Text('Grande (Internet lenta)')),
                      ],
                    ),
                  );
                  if (newSize != null) {
                    notifier.updateBufferSize(newSize);
                  }
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.skip_next),
                title: const Text('Autoplay (Séries)'),
                subtitle: const Text('Tocar próximo episódio automaticamente.'),
                value: settings.autoPlay,
                onChanged: (val) => notifier.updateAutoPlay(val),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Section: Parental
          _buildSectionTitle('Controle Parental'),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Definir PIN Parental'),
                subtitle: Text(settings.parentalPin.isEmpty ? 'Nenhum PIN configurado' : 'PIN configurado (****)'),
                trailing: const Icon(Icons.edit),
                onTap: () => _showPinDialog(context, settings.parentalPin),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Section: EPG
          _buildSectionTitle('Guia de Programação (EPG)'),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Ajuste de Fuso Horário (Time Shift)'),
                subtitle: Text('Deslocamento: ${settings.epgTimeShift > 0 ? '+' : ''}${settings.epgTimeShift} horas'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => notifier.updateEpgTimeShift(settings.epgTimeShift - 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => notifier.updateEpgTimeShift(settings.epgTimeShift + 1),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Section: Geral
          _buildSectionTitle('Interface e Geral'),
          _buildCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.access_time),
                title: const Text('Formato de Hora (24h)'),
                subtitle: const Text('Se desativado, usará formato AM/PM.'),
                value: settings.timeFormat24h,
                onChanged: (val) => notifier.updateTimeFormat(val),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cleaning_services),
                title: const Text('Limpar Cache de Imagens'),
                subtitle: const Text('Libera espaço no dispositivo apagando logos de canais.'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache de imagens limpo com sucesso!')),
                  );
                },
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('Versão do Aplicativo'),
                subtitle: Text('FluxIPTV v1.0.0'),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: children,
      ),
    );
  }

  String _getBufferName(int size) {
    switch (size) {
      case 0: return 'Pequeno (Rápido)';
      case 2: return 'Grande (Para net lenta)';
      default: return 'Médio (Recomendado)';
    }
  }
}
