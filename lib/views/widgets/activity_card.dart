import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/activity_model.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  const ActivityCard({super.key, required this.activity});

  Color _intensityColor(String intensity) {
    switch (intensity) {
      case 'High':
        return const Color(0xFFE53935);
      case 'Medium':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF66BB6A);
    }
  }

  void _openVideoDialog(BuildContext context) {
    if (activity.videoAsset.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No video available for ${activity.title}')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => _VideoDialog(
        title: activity.title,
        videoAsset: activity.videoAsset,
        emoji: activity.emoji,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(activity.emoji, style: const TextStyle(fontSize: 36)),
        title: Text(activity.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(activity.intensity,
                      style: TextStyle(
                          color: _intensityColor(activity.intensity),
                          fontSize: 12)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.timer_outlined, size: 16),
                Text(' ${activity.durationMinutes} min'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_outline),
          onPressed: () => _openVideoDialog(context),
        ),
      ),
    );
  }
}

// ─── Video Dialog ──────────────────────────────────────────────────────────────
class _VideoDialog extends StatefulWidget {
  final String title;
  final String videoAsset;
  final String emoji;

  const _VideoDialog({
    required this.title,
    required this.videoAsset,
    required this.emoji,
  });

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      if (kIsWeb) {
        // On web, VideoPlayerController.asset() has CORS issues because
        // the browser treats asset requests as cross-origin.
        // VideoPlayerController.networkUrl() with a relative URI works correctly
        // since Flutter web serves assets over HTTP from the same origin.
        //
        // Example: 'assets/videos/hiit.mp4' → Uri.parse('assets/videos/hiit.mp4')
        // This resolves relative to the app's base URL, avoiding CORS entirely.
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoAsset),
          httpHeaders: const {
            // No special headers needed for same-origin assets,
            // but added for completeness if you ever swap to a CDN.
            'Accept': 'video/mp4,video/*',
          },
        );
      } else {
        // On mobile: asset loading works natively with no CORS concerns.
        _controller = VideoPlayerController.asset(widget.videoAsset);
      }

      await _controller.initialize();
      _controller.addListener(_onVideoUpdate);
      _controller.setLooping(true); // loop workout demo videos

      if (mounted) {
        setState(() => _isInitialized = true);
        _controller.play();
      }
    } catch (e) {
      debugPrint(
          '[VideoDialog] Failed to load video: ${widget.videoAsset} — $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 48,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                  child: Row(
                    children: [
                      Text(widget.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white60, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),

                // ── Video Area ──
                GestureDetector(
                  onTap: _toggleControls,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_hasError)
                          _buildErrorPlaceholder()
                        else if (!_isInitialized)
                          _buildLoadingPlaceholder()
                        else
                          VideoPlayer(_controller),
                        if (_isInitialized && _showControls)
                          _buildControlsOverlay(),
                      ],
                    ),
                  ),
                ),

                // ── Progress Bar ──
                if (_isInitialized && !_hasError) _buildProgressBar(),

                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2563EB),
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: const Color(0xFF1C2537),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_rounded,
              color: Colors.white38, size: 40),
          const SizedBox(height: 10),
          Text(
            kIsWeb
                ? 'Video not available on web preview'
                : 'Could not load video',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          // Show web-specific hint
          if (kIsWeb) ...[
            const SizedBox(height: 6),
            Text(
              'Videos work on the installed app',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final isPlaying = _controller.value.isPlaying;
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.55),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: const Color(0xFF2563EB),
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: const Color(0x292563EB),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (v) {
                final seekTo = duration * v;
                _controller.seekTo(seekTo);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position),
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 11)),
                Text(_formatDuration(duration),
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
