import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'theme.dart';
import 'glass.dart';
import 'store_service.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class ViewerPage extends StatefulWidget {
  final List<AssetEntity> items;
  final int start;
  const ViewerPage({super.key, required this.items, required this.start});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late final PageController _pc;
  late int _i;
  Set<String> _favs = {};
  Timer? _timer;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _i = widget.start;
    _pc = PageController(initialPage: _i);
    StoreService.favorites().then((s) {
      if (mounted) setState(() => _favs = s);
    });
  }

  void _toggleSlideshow() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_i + 1 < widget.items.length) {
        _pc.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _timer?.cancel();
        if (mounted) setState(() => _playing = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.items[_i];
    final fav = _favs.contains(cur.id);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (context, i) =>
                _Page(asset: widget.items[i], active: i == _i),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).padding.top + 8,
            child: LiquidGlass(
              radius: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _playing ? Icons.pause : Icons.slideshow,
                      color: Colors.white,
                    ),
                    onPressed: _toggleSlideshow,
                  ),
                  IconButton(
                    icon: Icon(
                      fav ? Icons.star : Icons.star_border,
                      color: AppColors.gold,
                    ),
                    onPressed: () async {
                      await StoreService.toggleFav(cur.id);
                      final s = await StoreService.favorites();
                      if (mounted) setState(() => _favs = s);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white),
                    onPressed: () async {
                      await StoreService.moveToTrash([cur]);
                      if (context.mounted) Navigator.pop(context, true);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Page extends StatefulWidget {
  final AssetEntity asset;
  final bool active;
  const _Page({required this.asset, required this.active});

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  VideoPlayerController? _vc;

  @override
  void initState() {
    super.initState();
    if (widget.asset.type == AssetType.video) _initVideo();
  }

  Future<void> _initVideo() async {
    final File? f = await widget.asset.file;
    if (f == null) return;
    final c = VideoPlayerController.file(f);
    await c.initialize();
    if (!mounted) {
      c.dispose();
      return;
    }
    setState(() => _vc = c);
  }

  @override
  void didUpdateWidget(covariant _Page old) {
    super.didUpdateWidget(old);
    if (!widget.active) _vc?.pause();
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asset.type == AssetType.video) {
      final c = _vc;
      if (c == null) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.gold));
      }
      return GestureDetector(
        onTap: () =>
            setState(() => c.value.isPlaying ? c.pause() : c.play()),
        child: Center(
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
        ),
      );
    }
    return InteractiveViewer(
      child: Center(
        child: AssetEntityImage(
          widget.asset,
          isOriginal: false,
          thumbnailSize: const ThumbnailSize(1200, 1200),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
