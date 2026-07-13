import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flux_iptv/core/providers/streams_provider.dart';
import 'package:flux_iptv/core/models/stream_model.dart';
import 'package:intl/intl.dart';
import 'package:flux_iptv/core/utils/responsive_layout.dart';
import 'package:flux_iptv/core/providers/settings_provider.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateTime.now();
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
    final isMobile = ResponsiveLayout.isMobile(context);
    final settings = ref.watch(settingsProvider);
    final timeFormat = settings.timeFormat24h ? 'HH:mm' : 'hh:mm a';
    final fullFormat = settings.timeFormat24h ? 'HH:mm   MMM dd, yyyy' : 'hh:mm a   MMM dd, yyyy';

    final timeStr = isMobile 
        ? DateFormat(timeFormat).format(_currentTime)
        : DateFormat(fullFormat).format(_currentTime);

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
                timeStr,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = ResponsiveLayout.isMobile(context);
        final isTablet = ResponsiveLayout.isTablet(context);
        final isDesktop = ResponsiveLayout.isDesktopOrTV(context);
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        double tvHeight = isTablet ? 180 : (isDesktop ? 220 : 160);
        double movieHeight = isTablet ? 180 : (isDesktop ? 220 : 140);
        double extraHeight = isTablet ? 140 : (isDesktop ? 160 : 110);

        // Se for um celular em modo paisagem (tela deitada com pouca altura)
        if (isLandscape && constraints.maxHeight < 600) {
          final totalAvailable = constraints.maxHeight - 64; // Subtrai os paddings
          
          if (isMobile) {
            // No mobile temos 3 linhas, então dividimos o espaço por 3
            tvHeight = totalAvailable * 0.35;
            movieHeight = totalAvailable * 0.35;
            extraHeight = totalAvailable * 0.30;
          } else {
            // Em tablet/paisagem temos 2 linhas
            tvHeight = totalAvailable * 0.50;
            movieHeight = totalAvailable * 0.50;
            extraHeight = totalAvailable * 0.50;
          }
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48.0 : 16.0,
            vertical: isDesktop ? 32.0 : 8.0,
          ),
          child: Column(
            children: [
              if (isMobile) ...[
                // Mobile Layout (Current)
                _DashboardTile(
                  title: 'TV AO VIVO',
                  icon: Icons.tv,
                  gradientColors: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  height: tvHeight,
                  onTap: () => context.push('/content', extra: {'type': StreamType.live}),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardTile(
                        title: 'FILMES',
                        icon: Icons.movie,
                        gradientColors: const [Color(0xFFFF512F), Color(0xFFDD2476)],
                        height: movieHeight,
                        onTap: () => context.push('/content', extra: {'type': StreamType.movie}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DashboardTile(
                        title: 'SÉRIES',
                        icon: Icons.video_library,
                        gradientColors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        height: movieHeight,
                        onTap: () => context.push('/content', extra: {'type': StreamType.series}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardTile(
                        title: 'PLAYLISTS',
                        icon: Icons.playlist_add,
                        gradientColors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
                        height: extraHeight,
                        onTap: () => context.push('/add_playlist'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DashboardTile(
                        title: 'CONFIGURAÇÕES',
                        icon: Icons.settings,
                        gradientColors: const [Color(0xFF434343), Color(0xFF000000)],
                        height: extraHeight,
                        onTap: () => context.push('/settings'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Tablet/Desktop/TV Layout
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _DashboardTile(
                        title: 'TV AO VIVO',
                        icon: Icons.tv,
                        gradientColors: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        height: tvHeight,
                        onTap: () => context.push('/content', extra: {'type': StreamType.live}),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _DashboardTile(
                        title: 'FILMES',
                        icon: Icons.movie,
                        gradientColors: const [Color(0xFFFF512F), Color(0xFFDD2476)],
                        height: movieHeight,
                        onTap: () => context.push('/content', extra: {'type': StreamType.movie}),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _DashboardTile(
                        title: 'SÉRIES',
                        icon: Icons.video_library,
                        gradientColors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        height: movieHeight,
                        onTap: () => context.push('/content', extra: {'type': StreamType.series}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardTile(
                        title: 'PLAYLISTS',
                        icon: Icons.playlist_add,
                        gradientColors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
                        height: extraHeight,
                        onTap: () => context.push('/add_playlist'),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _DashboardTile(
                        title: 'CONFIGURAÇÕES',
                        icon: Icons.settings,
                        gradientColors: const [Color(0xFF434343), Color(0xFF000000)],
                        height: extraHeight,
                        onTap: () => context.push('/settings'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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

class _DashboardTile extends StatefulWidget {
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
  State<_DashboardTile> createState() => _DashboardTileState();
}

class _DashboardTileState extends State<_DashboardTile> {
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
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isFocused 
                    ? Colors.white.withOpacity(0.5) 
                    : widget.gradientColors.last.withOpacity(0.4),
                blurRadius: _isFocused ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: widget.height * 0.35, color: Colors.white),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
