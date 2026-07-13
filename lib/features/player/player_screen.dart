import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class PlayerScreen extends StatefulWidget {
  final String streamUrl;
  final String channelName;
  final bool isLive;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.channelName,
    this.isLive = true,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  String _errorMessage = '';

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl));
      
      await _videoPlayerController.initialize();
      await _videoPlayerController.play();
      
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.hasError) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = _videoPlayerController.value.errorDescription ?? 'Erro desconhecido no player';
            });
          }
        }
      });
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        isLive: widget.isLive,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightGreen,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Erro Chewie: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      
      setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.channelName),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
      ),
      body: Center(
        child: _hasError
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Falha ao carregar a transmissão.\nDetalhes: $_errorMessage',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              )
            : _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Focus(
                    autofocus: true,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        final key = event.logicalKey;
                        if (key == LogicalKeyboardKey.select ||
                            key == LogicalKeyboardKey.enter ||
                            key == LogicalKeyboardKey.numpadEnter ||
                            key == LogicalKeyboardKey.space ||
                            key == LogicalKeyboardKey.mediaPlayPause ||
                            key == LogicalKeyboardKey.mediaPlay ||
                            key == LogicalKeyboardKey.mediaPause) {
                          if (_videoPlayerController.value.isPlaying) {
                            _videoPlayerController.pause();
                          } else {
                            _videoPlayerController.play();
                          }
                          return KeyEventResult.handled;
                        } else if (key == LogicalKeyboardKey.arrowRight ||
                                   key == LogicalKeyboardKey.mediaFastForward) {
                          final currentPosition = _videoPlayerController.value.position;
                          final targetPosition = currentPosition + const Duration(seconds: 10);
                          _videoPlayerController.seekTo(targetPosition);
                          return KeyEventResult.handled;
                        } else if (key == LogicalKeyboardKey.arrowLeft ||
                                   key == LogicalKeyboardKey.mediaRewind) {
                          final currentPosition = _videoPlayerController.value.position;
                          final targetPosition = currentPosition - const Duration(seconds: 10);
                          _videoPlayerController.seekTo(
                            targetPosition.isNegative ? Duration.zero : targetPosition,
                          );
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Chewie(
                      controller: _chewieController!,
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        'Conectando ao canal...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
      ),
    );
  }
}
