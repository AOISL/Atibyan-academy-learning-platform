import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:first_mobile/main.dart' show supabase;

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String topicId;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
    required this.topicId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  String? _description;
  bool _isLoadingDescription = true;

  @override
  void initState() {
    super.initState();

    final videoId = YoutubePlayer.convertUrlToId(widget.url);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
        hideControls: false,
      ),
    );

    // Listen for fullscreen changes (button or rotation)
    _controller.addListener(() {
      final isFull = _controller.value.isFullScreen;
      if (isFull != _isFullScreen) {
        setState(() => _isFullScreen = isFull);
        _updateSystemUI();
      }
    });

    _fetchDescription();
  }

  Future<void> _fetchDescription() async {
    try {
      final response = await supabase
          .from('topics')
          .select('description')
          .eq('id', widget.topicId)
          .single();

      if (mounted) {
        setState(() {
          _description = response['description'] as String?;
          _isLoadingDescription = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDescription = false);
      }
      debugPrint('Error fetching description: $e');
    }
  }

  void _updateSystemUI() {
    if (_isFullScreen) {
      // Fullscreen: hide system bars, allow landscape
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      // Normal: show system bars, lock to portrait
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restore normal UI when leaving screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Completely hide AppBar in fullscreen mode
      appBar: _isFullScreen
          ? null
          : AppBar(title: Text(widget.title), centerTitle: true),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          return Stack(
            fit: StackFit.expand,
            children: [
              // The video player itself
              YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.blue,
                progressColors: const ProgressBarColors(
                  playedColor: Colors.blue,
                  handleColor: Colors.blueAccent,
                ),
                aspectRatio: isLandscape ? 16 / 9 : 16 / 9,
                bottomActions: [
                  CurrentPosition(),
                  const SizedBox(width: 8.0),
                  ProgressBar(isExpanded: true),
                  const SizedBox(width: 8.0),
                  RemainingDuration(),
                  const Spacer(),
                  FullScreenButton(controller: _controller),
                ],
              ),

              // Description overlay – only visible when NOT in fullscreen
              if (!_isFullScreen)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _isLoadingDescription ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      // Use withAlpha instead of deprecated withOpacity
                      color: Colors.black.withAlpha(166), // ≈ 65% opacity
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_description != null &&
                              _description!.trim().isNotEmpty)
                            Text(
                              _description!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            const Text(
                              'No description available for this topic.',
                              style: TextStyle(color: Colors.white54),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Loading indicator for description (only visible in normal mode)
              if (_isLoadingDescription && !_isFullScreen)
                const Positioned(
                  bottom: 24,
                  right: 24,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
