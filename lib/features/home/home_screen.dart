import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flux_iptv/core/providers/streams_provider.dart';
import 'package:flux_iptv/core/models/stream_model.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('HH:mm   MMM dd, yyyy');
    if (mounted) {
      setState(() {
        _currentTime = formatter.format(now);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streamsAsyncValue = ref.watch(streamsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12), // Deep dark modern background
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                Color(0xFF1A1A2E), // Slight blue tint at top
                Color(0xFF0D0D12), // Deep dark at bottom
              ],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: streamsAsyncValue.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                  error: (err, stack) => Center(child: Text('Erro: $err', style: const TextStyle(color: Colors.white))),
                  data: (streams) {
                    if (streams.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return _buildDashboard(context, streams);
                  },
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Area
          Row(
            children: [
              const Icon(Icons.live_tv, color: Colors.white, size: 32),
              const SizedBox(width: 8),
              Text(
                'FluxIPTV',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          // Time and User
          Row(
            children: [
              Text(
                _currentTime,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tv_off, size: 64, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Nenhuma lista IPTV configurada.', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/add_playlist'),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Playlist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<StreamModel> streams) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Live TV (Full Width)
          _DashboardTile(
            title: 'TV AO VIVO',
            icon: Icons.tv,
            gradientColors: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
            height: 160,
            onTap: () {
              context.push('/content', extra: {'type': StreamType.live});
            },
          ),
          const SizedBox(height: 16),
          // Movies & Series (Half Width)
          Row(
            children: [
              Expanded(
                child: _DashboardTile(
                  title: 'FILMES',
                  icon: Icons.movie,
                  gradientColors: const [Color(0xFFFF512F), Color(0xFFDD2476)],
                  height: 140,
                  onTap: () {
                    context.push('/content', extra: {'type': StreamType.movie});
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DashboardTile(
                  title: 'SÉRIES',
                  icon: Icons.video_library,
                  gradientColors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  height: 140,
                  onTap: () {
                    context.push('/content', extra: {'type': StreamType.series});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Lower utilities
          Row(
            children: [
              Expanded(
                child: _DashboardTile(
                  title: 'FAVORITOS',
                  icon: Icons.favorite,
                  gradientColors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                  height: 110,
                  onTap: () {
                    // TODO: Create a favorites filter or screen
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve')));
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DashboardTile(
                  title: 'PLAYLISTS',
                  icon: Icons.playlist_add,
                  gradientColors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
                  height: 110,
                  onTap: () {
                    context.push('/add_playlist');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DashboardTile(
            title: 'CONFIGURAÇÕES',
            icon: Icons.settings,
            gradientColors: const [Color(0xFF434343), Color(0xFF000000)],
            height: 90,
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve')));
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Expiração: Ilimitado',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
          Text(
            'Usuário logado',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final double height;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: height * 0.35, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
