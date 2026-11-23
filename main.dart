import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const MeriGalleryApp());

class MeriGalleryApp extends StatelessWidget {
  const MeriGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E), brightness: b),
          scaffoldBackgroundColor: b == Brightness.dark
              ? const Color(0xFF101416)
              : const Color(0xFFF3F1EE),
        );
    return MaterialApp(
      title: 'Meri Gallery',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const Gate(),
    );
  }
}

/// Asks for permission, then shows the app.
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  PermissionState? _ps;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  Future<void> _ask() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (mounted) setState(() => _ps = ps);
  }

  @override
  Widget build(BuildContext context) {
    if (_ps == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_ps!.hasAccess) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library_outlined, size: 64),
                const SizedBox(height: 16),
                Text('Gallery dekhne ke liye permission chahiye',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                FilledButton(onPressed: _ask, child: const Text('Allow')),
                TextButton(
                    onPressed: PhotoManager.openSetting,
                    child: const Text('Settings kholein')),
              ],
            ),
          ),
        ),
      );
    }
    return const Shell();
  }
}

/// Two separate galleries: Photos and Videos.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: const [
        MediaGrid(type: RequestType.image, title: 'Photos', unit: 'photos'),
        MediaGrid(type: RequestType.video, title: 'Videos', unit: 'videos'),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.photo_outlined),
              selectedIcon: Icon(Icons.photo),
              label: 'Photos'),
          NavigationDestination(
              icon: Icon(Icons.videocam_outlined),
              selectedIcon: Icon(Icons.videocam),
              label: 'Videos'),
        ],
      ),
    );
  }
}

String _fmt(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

String _date(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

class MediaGrid extends StatefulWidget {
  final RequestType type;
  final String title;
  final String unit;
  const MediaGrid(
      {super.key, required this.type, required this.title, required this.unit});
  @override
  State<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<MediaGrid> {
  static const _size = 90;
  final _items = <AssetEntity>[];
  final _scroll = ScrollController();
  AssetPathEntity? _path;
  int _page = 0, _total = 0;
  bool _loading = false, _done = false, _ready = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    PhotoManager.addChangeCallback(_onChange);
    PhotoManager.startChangeNotify();
    _init();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_onChange);
    _scroll.dispose();
    super.dispose();
  }

  void _onChange(MethodCall _) => _init();

  Future<void> _init() async {
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: widget.type,
      filterOption: FilterOptionGroup(orders: [
        const OrderOption(type: OrderOptionType.createDate, asc: false)
      ]),
    );
    if (!mounted) return;
    if (paths.isEmpty) {
      setState(() {
        _items.clear();
        _total = 0;
        _done = true;
        _ready = true;
      });
      return;
    }
    _path = paths.first;
    final total = await _path!.assetCountAsync;
    final first = await _path!.getAssetListPaged(page: 0, size: _size);
    if (!mounted) return;
    setState(() {
      _total = total;
      _items
        ..clear()
        ..addAll(first);
      _page = 1;
      _done = _items.length >= _total;
      _ready = true;
    });
  }

  Future<void> _more() async {
    if (_loading || _done || _path == null) return;
    _loading = true;
    final next = await _path!.getAssetListPaged(page: _page, size: _size);
    if (!mounted) return;
    setState(() {
      _items.addAll(next);
      _page++;
      _done = next.isEmpty || _items.length >= _total;
    });
    _loading = false;
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 800) {
      _more();
    }
  }

  Future<void> _open(int i) async {
    final deleted = await Navigator.of(context).push<Set<String>>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Viewer(items: List.of(_items), index: i),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
    if (deleted != null && deleted.isNotEmpty) {
      setState(() {
        _items.removeWhere((e) => deleted.contains(e.id));
        _total -= deleted.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _init,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
              title: Text(widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('$_total ${widget.unit}',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          ),
          if (_ready && _items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: Text('Koi ${widget.unit} nahi mili',
                      style: TextStyle(color: cs.onSurfaceVariant))),
            )
          else
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final a = _items[i];
                  return GestureDetector(
                    onTap: () => _open(i),
                    child: Stack(fit: StackFit.expand, children: [
                      AssetEntityImage(a,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize.square(320),
                          fit: BoxFit.cover),
                      if (a.type == AssetType.video)
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(_fmt(a.videoDuration),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ),
                        ),
                    ]),
                  );
                },
                childCount: _items.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/// Full-screen viewer: swipe between items, pinch to zoom, delete.
class Viewer extends StatefulWidget {
  final List<AssetEntity> items;
  final int index;
  const Viewer({super.key, required this.items, required this.index});
  @override
  State<Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<Viewer> {
  late final PageController _pc = PageController(initialPage: widget.index);
  late final List<AssetEntity> _items = List.of(widget.items);
  late int _cur = widget.index;
  final _deleted = <String>{};
  bool _chrome = true;

  Future<void> _delete() async {
    final a = _items[_cur];
    final res = await PhotoManager.editor.deleteWithIds([a.id]);
    if (res.isEmpty || !mounted) return;
    _deleted.add(a.id);
    if (_items.length == 1) {
      Navigator.pop(context, _deleted);
      return;
    }
    setState(() {
      _items.removeAt(_cur);
      if (_cur >= _items.length) _cur = _items.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = _items[_cur];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _deleted);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          PageView.builder(
            controller: _pc,
            itemCount: _items.length,
            onPageChanged: (i) => setState(() => _cur = i),
            itemBuilder: (_, i) {
              final it = _items[i];
              return it.type == AssetType.video
                  ? VideoPage(key: ValueKey(it.id), asset: it, active: i == _cur)
                  : PhotoPage(
                      key: ValueKey(it.id),
                      asset: it,
                      onTap: () => setState(() => _chrome = !_chrome));
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_chrome,
              child: AnimatedOpacity(
                opacity: _chrome ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black87, Colors.transparent])),
                  child: Row(children: [
                    IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context, _deleted)),
                    Expanded(
                      child: Text(_date(a.createDateTime),
                          style: const TextStyle(color: Colors.white)),
                    ),
                    Text('${_cur + 1} / ${_items.length}',
                        style: const TextStyle(color: Colors.white70)),
                    IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _delete),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class PhotoPage extends StatefulWidget {
  final AssetEntity asset;
  final VoidCallback onTap;
  const PhotoPage({super.key, required this.asset, required this.onTap});
  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final _tc = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _tc.addListener(() {
      final z = _tc.value.getMaxScaleOnAxis() > 1.01;
      if (z != _zoomed) setState(() => _zoomed = z);
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: () => _tc.value =
          _zoomed ? Matrix4.identity() : (Matrix4.identity()..scale(2.5)),
      child: InteractiveViewer(
        transformationController: _tc,
        minScale: 1,
        maxScale: 5,
        panEnabled: _zoomed,
        child: Center(
          child: AssetEntityImage(widget.asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize(1600, 1600),
              fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class VideoPage extends StatefulWidget {
  final AssetEntity asset;
  final bool active;
  const VideoPage({super.key, required this.asset, required this.active});
  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController? _c;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final f = await widget.asset.file;
    if (f == null || !mounted) return;
    final c = VideoPlayerController.file(f);
    await c.initialize();
    if (!mounted) {
      c.dispose();
      return;
    }
    c.setLooping(true);
    c.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() => _c = c);
    if (widget.active) c.play();
  }

  @override
  void didUpdateWidget(VideoPage old) {
    super.didUpdateWidget(old);
    final c = _c;
    if (c == null) return;
    if (widget.active && !old.active) c.play();
    if (!widget.active && old.active) {
      c.pause();
      c.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final v = c.value;
    final total = v.duration.inMilliseconds.toDouble();
    final pos = v.position.inMilliseconds.toDouble().clamp(0, total);
    return GestureDetector(
      onTap: () => v.isPlaying ? c.pause() : c.play(),
      child: Stack(alignment: Alignment.center, children: [
        AspectRatio(aspectRatio: v.aspectRatio, child: VideoPlayer(c)),
        if (!v.isPlaying)
          Container(
            decoration: const BoxDecoration(
                color: Colors.black45, shape: BoxShape.circle),
            padding: const EdgeInsets.all(14),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 44),
          ),
        Positioned(
          left: 8,
          right: 8,
          bottom: MediaQuery.of(context).padding.bottom + 12,
          child: Row(children: [
            Text(_fmt(v.position),
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            Expanded(
              child: Slider(
                value: pos.toDouble(),
                max: total <= 0 ? 1 : total,
                onChanged: (x) => c.seekTo(Duration(milliseconds: x.toInt())),
              ),
            ),
            Text(_fmt(v.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
